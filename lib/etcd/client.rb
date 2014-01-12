require 'net/http'
require 'json'
require 'etcd/log'
require 'etcd/stats'
require 'etcd/keys'
require 'etcd/exceptions'
require 'etcd/mod/lock'
require 'etcd/mod/leader'

module Etcd
  ##
  # This is the central ruby class for Etcd. It provides methods for all Etcd api calls.
  # It also provides few additional methods beyond the core Etcd api, like Etcd::Client#lock
  # and Etcd::Client#eternal_watch, they are defined in separate modules and included in this
  # class
  class Client

    HTTP_REDIRECT = ->(r){ r.is_a? Net::HTTPRedirection }
    HTTP_SUCCESS = ->(r){ r.is_a? Net::HTTPSuccess }
    HTTP_CLIENT_ERROR = ->(r){ r.is_a? Net::HTTPClientError }

    include Stats
    include Keys
    include Mod::Lock
    include Mod::Leader

    attr_reader :host, :port, :http, :allow_redirect, :use_ssl, :verify_mode, :read_timeout

    ##
    # Creates a new instance of Etcd::Client. It accepts a hash +opts+ as argument
    # 
    # @param [Hash] opts The options for new Etcd::Client object
    # @opts [String] :host IP address of the etcd server (default is '127.0.0.1')
    # @opts [Fixnum] :port Port number of the etcd server (default is 4001)
    # @opts [Fixnum] :read_timeout Set default HTTP read timeout for all api calls (default is 60)
    def initialize(opts={})
      @host = opts[:host] || '127.0.0.1'
      @port = opts[:port] || 4001
      @read_timeout = opts[:read_timeout] || 60
      @allow_redirect = opts.has_key?(:allow_redirect) ? opts[:allow_redirect] : true
      @use_ssl = opts[:use_ssl] || false
      @verify_mode = opts[:verify_mode] || OpenSSL::SSL::VERIFY_PEER
    end

    # Returns the etcd api version that will be used for across API methods
    def version_prefix
      '/v2'
    end

    # Return the etcd cluster version
    def version
      api_execute('/version', :get).body
    end

    # Lists all machines in the cluster
    def machines
      api_execute( version_prefix + '/machines', :get).body.split(",").map(&:strip)
    end

    # Get the current leader in a cluster
    def leader
      api_execute( version_prefix + '/leader', :get).body.strip
    end

    # This method sends api request to etcd server.
    #
    # This method has following parameters as argument
    # * path    - etcd server path (etcd server end point)
    # * method  - the request method used
    # * options  - any additional parameters used by request method (optional)
    def api_execute(path, method, options={})
      params = options[:params]
      timeout = options[:timeout] || @read_timeout

      http = if path=~/^http/
                uri = URI.parse(path)
                path =  uri.path
                Net::HTTP.new(uri.host, uri.port)
              else
                Net::HTTP.new(host, port)
              end
      http.read_timeout = timeout
      http.use_ssl = use_ssl
      http.verify_mode = verify_mode

      case  method
      when :get
        unless params.nil?
          encoded_params = URI.encode_www_form(params)
          path+= "?" + encoded_params
        end
        req = Net::HTTP::Get.new(path)
      when :post
        req = Net::HTTP::Post.new(path)
        unless params.nil?
          encoded_params = URI.encode_www_form(params)
          req.body= encoded_params
        end
        Log.debug("Setting body for post '#{encoded_params}'")
      when :put
        encoded_params = URI.encode_www_form(params)
        req = Net::HTTP::Put.new(path)
        req.body= encoded_params
        Log.debug("Setting body for put '#{encoded_params}'")
      when :delete
        unless params.nil?
          encoded_params = URI.encode_www_form(params)
          path+= "?" + encoded_params
        end
        req = Net::HTTP::Delete.new(path)
      else
        raise "Unknown http action: #{method}"
      end

      Log.debug("Invoking: '#{req.class}' against '#{path}")
      res = http.request(req)
      Log.debug("Response code: #{res.code}")

      case res
      when HTTP_SUCCESS
        Log.debug("Http success")
        res
      when HTTP_REDIRECT
        if allow_redirect
          Log.debug("Http redirect, following")
          api_execute(res['location'], method, params: params)
        else
          Log.debug("Http redirect not allowed")
          res.error!
        end
      when HTTP_CLIENT_ERROR
        raise Error.from_http_response(res)
      else
        Log.debug("Http error")
        Log.debug(res.body)
        res.error!
      end
    end
  end
end
