# Encoding: utf-8

require 'openssl'
require 'net/http'
require 'net/https'
require 'json'
require 'etcd/log'
require 'etcd/stats'
require 'etcd/keys'
require 'etcd/exceptions'
require 'etcd/mod/lock'
require 'etcd/mod/leader'

module Etcd
  ##
  # This is the central ruby class for Etcd. It provides methods for all
  # etcd api calls. It also provides few additional methods beyond the core
  # etcd api, like Etcd::Client#lock and Etcd::Client#eternal_watch, they
  # are defined in separate modules and included in this class
  class Client

    extend Forwardable

    HTTP_REDIRECT = ->(r) { r.is_a? Net::HTTPRedirection }
    HTTP_SUCCESS = ->(r) { r.is_a? Net::HTTPSuccess }
    HTTP_CLIENT_ERROR = ->(r) { r.is_a? Net::HTTPClientError }

    include Stats
    include Keys
    include Mod::Lock
    include Mod::Leader

    Config = Struct.new(:use_ssl, :verify_mode, :read_timeout, :ssl_key, :ca_file,
                        :user_name, :password, :allow_redirect, :ssl_cert)

    def_delegators :@config, :use_ssl, :verify_mode, :read_timeout
    def_delegators :@config, :user_name, :password, :allow_redirect


    attr_reader :seed_hosts, :http, :config

    ##
    # Creates an Etcd::Client object. It accepts a hash +opts+ as argument
    #
    # @param [Hash] opts The options for new Etcd::Client object
    # @opts [String] :host IP address of the etcd server (default 127.0.0.1)
    # @opts [Fixnum] :port Port number of the etcd server (default 4001)
    # @opts [Fixnum] :read_timeout set HTTP read timeouts (default 60)
    # rubocop:disable CyclomaticComplexity
    def initialize(opts = {})
      @seed_hosts = opts[:seed_hosts] || ['http://127.0.0.1:4001']
      @config = Config.new
      @config.read_timeout = opts[:read_timeout] || 60
      @config.allow_redirect = opts.key?(:allow_redirect) ? opts[:allow_redirect] : true
      @config.use_ssl = opts[:use_ssl] || false
      @config.verify_mode = opts.key?(:verify_mode) ? opts[:verify_mode] : OpenSSL::SSL::VERIFY_PEER
      @config.user_name = opts[:user_name] || nil
      @config.password = opts[:password] || nil
      @config.allow_redirect = opts.key?(:allow_redirect) ? opts[:allow_redirect] : true
      yield @config if block_given?
      # This is a hack which sets cluster to seed_host and then uses that to
      # find an online server to get the current server list.
      @cluster = @seed_hosts
      begin
        machines
      rescue AllNodesDown => e
        Log.warn "All nodes are currently down!"
      end
    end
    # rubocop:enable CyclomaticComplexity

    # Returns the etcd api version that will be used for across API methods
    def version_prefix
      '/v2'
    end

    # Returns the etcd daemon version
    def version
      api_execute('/version', :get).body
    end

    # Returns array of all machines in the cluster
    def machines
      @cluster = api_execute(version_prefix + '/machines', :get).body.split(',').map(&:strip)
    end

    # Get the current leader
    def leader
      api_execute(version_prefix + '/leader', :get).body.strip
    end

    # This method sends api request to etcd server.
    #
    # This method has following parameters as argument
    # * path    - etcd server path (etcd server end point)
    # * method  - the request method used
    # * options  - any additional parameters used by request method (optional)
    # rubocop:disable MethodLength, CyclomaticComplexity
    def api_execute(path, method, options = {})
      params = options[:params]
      case  method
      when :get
        req = build_http_request(Net::HTTP::Get, path, params)
      when :post
        req = build_http_request(Net::HTTP::Post, path, nil, params)
      when :put
        req = build_http_request(Net::HTTP::Put, path, nil, params)
      when :delete
        req = build_http_request(Net::HTTP::Delete, path, params)
      else
        fail "Unknown http action: #{method}"
      end
      timeout = options[:timeout] || @read_timeout
      @cluster.each do |machine|
        begin
          uri = URI(machine)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = timeout
          setup_https(http)
          req.basic_auth(user_name, password) if [user_name, password].all?
          Log.debug("Invoking: '#{req.class}' against '#{path}")
          res = http.request(req)
          Log.debug("Response code: #{res.code}")
          return process_http_request(res, req, params)
        rescue Errno::ECONNREFUSED, Net::HTTPRequestTimeOut => e
          next
        end
      end
      raise AllNodesDown
    end

    def setup_https(http)
      http.use_ssl = use_ssl
      http.verify_mode = verify_mode
      unless config.ssl_cert.nil?
        Log.debug('Setting up ssl cert')
        http.cert = config.ssl_cert
      end
      unless config.ssl_key.nil?
        Log.debug('Setting up ssl key')
        http.key = config.ssl_key
      end
      unless config.ca_file.nil?
        Log.debug('Setting up ssl ca file to :' + config.ca_file)
        http.ca_file = config.ca_file
      end
    end

    # need to ahve original request to process the response when it redirects
    def process_http_request(res, req = nil, params = nil)
      case res
      when HTTP_SUCCESS
        Log.debug('Http success')
        res
      when HTTP_REDIRECT
        if allow_redirect
          uri = URI(res['location'])
          @host = uri.host
          @port = uri.port
          Log.debug("Http redirect, setting new host to: #{@host}:#{@port}, and retrying")
          api_execute(uri.path, req.method.downcase.to_sym, params: params)
        else
          Log.debug('Http redirect not allowed')
          res.error!
        end
      when HTTP_CLIENT_ERROR
        fail Error.from_http_response(res)
      else
        Log.debug('Http error')
        Log.debug(res.body)
        res.error!
      end
    end
    # rubocop:enable MethodLength

    def build_http_request(klass, path, params = nil, body = nil)
      path += '?' + URI.encode_www_form(params) unless params.nil?
      req = klass.new(path)
      req.body = URI.encode_www_form(body) unless body.nil?
      Etcd::Log.debug("Built #{klass} path:'#{path}'  body:'#{req.body}'")
      req
    end
  end
end
