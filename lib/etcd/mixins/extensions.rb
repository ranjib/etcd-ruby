require 'etcd/lock'

module Etcd
  module Extensions

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

    def lock(opts={})
      opts[:client] = self
      lock = Lock.new(opts)
      lock.acquire
      begin
        yield lock.lock_id
      rescue Exception => e
        raise e
      ensure
        lock.release
      end
    end  
  end
end
