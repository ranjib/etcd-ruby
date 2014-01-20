# Encoding: utf-8

require 'json'
require 'etcd/response'
require 'etcd/log'

module Etcd
  # Keys module provides the basic key value operations against
  # etcd /keys namespace
  module Keys
    # return etcd endpoint that is reserved for key/value store
    def key_endpoint
      version_prefix + '/keys'
    end

    # Retrives a key with its associated data, if key is not present it will
    # return with message "Key Not Found"
    #
    # This method has following parameters as argument
    # * key - whose data to be retrive
    def get(key, opts = {})
      response = api_execute(key_endpoint + key, :get, params: opts)
      Response.from_http_response(response)
    end

    # Create or update a new key
    #
    # This method has following parameters as argument
    # * key   - whose value to be set
    # * value - value to be set for specified key
    # * ttl   - shelf life of a key (in secsonds) (optional)
    def set(key, opts = {})
      raise ArgumentError, 'Second argument must be a hash' unless opts.is_a?(Hash)
      path  = key_endpoint + key
      payload = {}
      [:ttl, :value, :dir, :prevExist, :prevValue, :prevIndex].each do |k|
        payload[k] = opts[k] if opts.key?(k)
      end
      response = api_execute(path, :put, params: payload)
      Response.from_http_response(response)
    end

    # Deletes a key (and its content)
    #
    # This method has following parameters as argument
    # * key - key to be deleted
    def delete(key, opts = {})
      response = api_execute(key_endpoint + key, :delete, params: opts)
      Response.from_http_response(response)
    end

    # Set a new value for key if previous value of key is matched
    #
    # This method takes following parameters as argument
    # * key       - whose value is going to change if previous value is matched
    # * value     - new value to be set for specified key
    # * prevValue - value of a key to compare with existing value of key
    # * ttl       - shelf life of a key (in secsonds) (optional)
    def compare_and_swap(key,opts= {})
      path  = key_endpoint + key
      raise ArgumentError, 'Second argument must be a hash' unless opts.is_a?(Hash)
      raise ArgumentError, 'You must pass prevValue' unless opts.key?(:prevValue)
      set(key,opts)
    end

    # Gives a notification when specified key changes
    #
    # This method has following parameters as argument
    # @ key   - key to be watched
    # @options [Hash] additional options for watching a key
    # @options [Fixnum] :index watch the specified key from given index
    # @options [Fixnum] :timeout specify http timeout
    def watch(key, opts = {})
      params = { wait: true }
      raise ArgumentError, 'Second argument must be a hash' unless opts.is_a?(Hash)
      timeout = opts[:timeout] || @read_timeout
      index = opts[:waitIndex] || opts[:index]
      params[:waitIndex] = index unless index.nil?
      params[:consistent] = opts[:consistent] if opts.key?(:consistent)

      response = api_execute(key_endpoint + key, :get,
                             timeout: timeout, params: params)
      Response.from_http_response(response)
    end

    # Creates nested keys, where parent key is directory
    # This method has following parameters as argument
    # @dir    - nested key path with directory name(s)
    # @options [Hash] additional options for creating a key with nested directory structure
    def create_in_order(dir, opts = {})
      path  = key_endpoint + dir
      raise ArgumentError, 'Second argument must be a hash' unless opts.is_a?(Hash)
      payload = {}
      [:ttl, :value].each do |k|
        payload[k] = opts[k] if opts.key?(k)
      end
      response = api_execute(path, :post, params: payload)
      Response.from_http_response(response)
    end

    # Checks existance of a given key and returns true if key is present
    #
    # This method has following parameters as argument
    # @ key   - key to be checked
    def exists?(key)
      begin
        Etcd::Log.debug("Checking if key:' #{key}' exists")
        get(key)
        true
      rescue KeyNotFound => e
        Etcd::Log.debug("Key does not exist #{e}")
        false
      end
    end

    # Create/adds a new key
    #
    # This method has following parameters as argument
    # * key       - key to be created
    # * value     - new value to be set for specified key
    # * ttl       - shelf life of a key (in secsonds) (optional)
    def create(key, opts = {})
      set(key, opts.merge({ prevExist: false}))
    end

    # Updates an existing key
    #
    # This method has following parameters as argument
    # * key       - key to be created
    # * value     - new value to be set for existing key
    # * ttl       - shelf life of a key (in secsonds) (optional)
    def update(key, opts = {})
      set(key, opts.merge({ prevExist: true}))
    end

    # Gives a notification whenever specified key changes
    #
    # This method has following parameters as argument
    # @ key   - key to be watched
    def eternal_watch(key, index = nil)
      loop do
        response = watch(key, index)
        yield response
      end
    end

    alias_method :key?, :exists?
    alias_method :exist?, :exists?
    alias_method :has_key?, :exists?
    alias_method :test_and_set, :compare_and_swap
  end
end
