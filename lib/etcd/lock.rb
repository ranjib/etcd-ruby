require 'uuid'

module Etcd
  class Lock

    class LockAcqusitionFailure < StandardError; end
    class LockReleaseFailure < StandardError; end

    attr_reader :lock_id, :key, :value

    def initialize(opts={})
      @client = opts[:client]
      @key = opts[:key] || '/global/lock' 
      @value = opts[:value] || 0
    end

    def acquire
      @lock_id =  uuid.generate
      begin
        client.test_and_set(key, lock_id, value)
      rescue Exception => e  
        raise LockAcqusitionFailure, e.message
      end
    end

    def release
      begin
        client.test_and_set(key, value, lock_id)
      rescue Exception => e
        raise LockReleaseFailure, e.message
      end
    end

    def uuid
      @uuid ||= UUID.new
    end
  end
end
