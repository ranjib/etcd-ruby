# Encoding: utf-8

require 'timeout'

module Etcd
  module Mod
    # Implement Etcd's Leader module
    module Leader
      def mod_leader_endpoint
        '/mod/v2/leader'
      end

      def set_leader(key, value, ttl)
        path = mod_leader_endpoint + "#{key}?ttl=#{ttl}"
        api_execute(path, :put, params: { name: value }).body
      end

      def get_leader(key)
        api_execute(mod_leader_endpoint + key, :get).body
      end

      def delete_leader(key, value)
        path = mod_leader_endpoint + key + '?' + URI.encode_www_form(name: value)
        api_execute(path, :delete).body
      end
    end
  end
end
