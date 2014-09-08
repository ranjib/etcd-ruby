# Encoding: utf-8

require 'timeout'

module Etcd
  module Mod
    # implement etcd lock module
    module Lock
      def mod_lock_endpoint
        '/mod/v2/lock'
      end

      def acquire_lock(key, ttl, opts = {})
        path = mod_lock_endpoint + key + "?ttl=#{ttl}"
        timeout = opts[:timeout] || 60
        Timeout.timeout(timeout) do
          return api_execute(path, :post, :params => opts).body
        end
      end

      def renew_lock(key, ttl, opts = {})
        unless opts.key?(:index) || opts.key?(:value)
          fail ArgumentError, 'You mast pass index or value'
        end
        path = mod_lock_endpoint + key + "?ttl=#{ttl}"
        timeout = opts[:timeout] || 60
        Timeout.timeout(timeout) do
          api_execute(path, :put, :params => opts).body
        end
      end

      def get_lock(key, opts = {})
        api_execute(mod_lock_endpoint + key, :get, :params => opts).body
      end

      def delete_lock(key, opts = {})
        unless opts.key?(:index) || opts.key?(:value)
          fail ArgumentError, 'You must pass index or value'
        end
        api_execute(mod_lock_endpoint + key, :delete, :params => opts)
      end

      # rubocop:disable RescueException
      def lock(key, ttl, opts = {})
        key = "/" + key unless key.start_with? '/'
        lock_index = acquire_lock(key, ttl, opts)
        begin
          yield key
        rescue Exception => e
          raise e
        ensure
          delete_lock(key, :index => lock_index)
        end
      end
      # rubocop:enable RescueException

      alias_method :retrive_lock, :get_lock
      alias_method :release_lock, :delete_lock
    end
  end
end
