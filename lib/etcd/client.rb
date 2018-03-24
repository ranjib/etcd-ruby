# Encoding: utf-8

require 'openssl'
require 'json'
require 'faraday'
require 'etcd/log'
require 'etcd/stats'
require 'etcd/keys'
require 'etcd/exceptions'

module Etcd
  ##
  # This is the central ruby class for Etcd. It provides methods for all
  # etcd api calls. It also provides few additional methods beyond the core
  # etcd api, like Etcd::Client#lock and Etcd::Client#eternal_watch, they
  # are defined in separate modules and included in this class
  class Client
    extend Forwardable

    include Stats
    include Keys

    Config = Struct.new(
      :use_ssl,
      :verify_mode,
      :read_timeout,
      :ssl_key,
      :ca_file,
      :user_name,
      :password,
      :ssl_cert,
    )

    def_delegators :@config, :use_ssl, :verify_mode, :read_timeout
    def_delegators :@config, :user_name, :password

    attr_reader :host, :port, :http, :active_endpoint, :endpoints, :config

    ##
    # Creates an Etcd::Client object. It accepts a hash +opts+ as argument
    #
    # @param [Hash] opts The options for new Etcd::Client object
    # @opts [String] :host IP address of the etcd server (default 127.0.0.1)
    # @opts [Fixnum] :port Port number of the etcd server (default 4001)
    # @opts [Fixnum] :read_timeout set HTTP read timeouts (default 60)
    # rubocop:disable CyclomaticComplexity
    def initialize(opts = {})
      raise ArgumentError.new('either set endpoints OR host/port options') if (opts[:host] or opts [:port]) and opts[:endpoints]
      raise ArgumentError.new('when using endpoints instead of host/port options set protocol in endpoint instead of using use_ssl option(ie: "http://host:port" or https://host:port)') if not opts[:use_ssl].nil? and opts[:endpoints]
      @host = opts[:host] || '127.0.0.1'
      @port = opts[:port] || 4001
      proto = (opts.key?(:use_ssl) and opts[:use_ssl]) ? "https" : "http"
      @endpoints = opts[:endpoints] || ["#{proto}://#{@host}:#{@port}"]
      @active_endpoint = @endpoints.sample
      Log.debug("initialised etcd client with endpoints: #{@endpoints}")
      @config = Config.new
      @config.read_timeout = opts[:read_timeout] || 60
      @config.use_ssl = opts[:use_ssl] || false
      @config.verify_mode = opts.key?(:verify_mode) ? opts[:verify_mode] : OpenSSL::SSL::VERIFY_PEER
      @config.user_name = opts[:user_name] || nil
      @config.password = opts[:password] || nil
      @config.ca_file = opts.key?(:ca_file) ? opts[:ca_file] : nil
      # Provide a OpenSSL X509 cert here and not the path. See README
      @config.ssl_cert = opts.key?(:ssl_cert) ? opts[:ssl_cert] : nil
      # Provide the key (content) and not just the filename here.
      @config.ssl_key = opts.key?(:ssl_key) ? opts[:ssl_key] : nil
      yield @config if block_given?
    end
    # rubocop:enable CyclomaticComplexity

    # Returns the etcd api version that will be used for across API methods
    def version_prefix
      '/v2'
    end

    # Returns the etcd daemon version
    def version
      version_response = api_execute('/version', :get).body
      begin
        "etcd v" + JSON.parse(version_response)['etcdserver']
      rescue JSON::ParserError
        version_response
      end
    end

    def members
      JSON.parse(api_execute(version_prefix + '/members', :get).body.strip)['members']
    end

    def refresh_endpoints
      @endpoints = members.collect{|member| member['clientURLs']}.flatten
    end

    # Get the current leader
    def leader
      api_execute(version_prefix + '/stats/leader', :get).body.strip
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
      request_params = nil
      request_body = nil
      case  method
      when :get, :delete
        request_params = params
      when :post, :put
        request_body = params
      else
        fail "Unknown http action: #{method}"
      end
      http = Faraday.new(@active_endpoint, request: {
          timeout: options[:timeout] || read_timeout
      })
      setup_https(http)
      http.basic_auth(user_name, password) if [user_name, password].all?
      Log.debug("Invoking: '#{method}' against '#{path}")
      http.params = request_params if not request_params.nil?
      res = http.run_request(method, path, request_body, {})
      Log.debug("Response code: #{res.status}")
      Log.debug("Response body: #{res.body}")
      process_http_request(res)
    end

    def setup_https(http)
      http.ssl.verify = verify_mode
      if config.ssl_cert
        Log.debug('Setting up ssl cert')
        http.ssl.client_cert = config.ssl_cert
      end
      if config.ssl_key
        Log.debug('Setting up ssl key')
        http.ssl.client_key = config.ssl_key
      end
      if config.ca_file
        Log.debug('Setting up ssl ca file to :' + config.ca_file)
        http.ssl.ca_file = config.ca_file
      end
    end

    # need to have original request to process the response when it redirects
    def process_http_request(res)
      case res.success?
      when true
        Log.debug('Http success')
        res
      when false
        fail Error.from_http_response(res)
      else
        Log.debug('Http error')
        Log.debug(res.body)
      end
    end
    # rubocop:enable MethodLength

    def build_http_request(klass, path, params = nil, body = nil)
      path += '?' + URI.encode_www_form(params) unless params.nil?
      req = Faraday::Request.new('get')
      req.body = URI.encode_www_form(body) unless body.nil?
      Etcd::Log.debug("Built #{klass} path:'#{path}'  body:'#{req.body}'")
      req
    end
  end
end
