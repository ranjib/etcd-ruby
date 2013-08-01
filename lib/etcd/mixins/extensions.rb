module Etcd
  module Extensions

    def eternal_watch(key, index=nil)
      loop do
        response = watch(key, index)
        yield response
      end
    end

    def lock(key, value, prevValue, ttl = nil)
      response = test_and_set(key, value, prevValue, ttl = nil)
      yield response
    end
  end
end
