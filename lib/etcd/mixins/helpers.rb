require 'etcd/lock'

module Etcd
  module Helpers

    def has_key?(key)
      begin
        get(key)
        true
      rescue Net::HTTPServerException => e
        false
      end
    end

    def eternal_watch(key, index=nil)
      loop do
        response = watch(key, index)
        yield response
      end
    end
  end
end
