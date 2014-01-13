# Encoding: utf-8

require 'json'

module Etcd
  module Stats

    def stats_endpoint
      version_prefix + '/stats'
    end

    def stats(type)
      case type
      when :leader
        JSON.parse(api_execute(stats_endpoint+'/leader', :get).body)
      when :store
        JSON.parse(api_execute(stats_endpoint+'/store', :get).body)
      when :self
        JSON.parse(api_execute(stats_endpoint+'/self', :get).body)
      else
        raise ArgumentError, "Invalid stats type '#{type}'"
      end
    end
  end
end
