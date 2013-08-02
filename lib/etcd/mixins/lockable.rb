module Etcd
  module Lockable
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
