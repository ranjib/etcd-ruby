require 'uuid'

module Etcd
  class Lock

    class LockAcqusitionFailure < StandardError; end
    class LockReleaseFailure < StandardError; end

    attr_reader :lock_id, :key, :value, :client
    attr_reader :retries, :retry_interval, :attempts


    def initialize(opts={})
      @client = opts[:client]
      @key = opts[:key] || '/global/lock' 
      @value = opts[:value] || 0
      @retries = opts[:retries] || 1
      @retry_interval = opts[:retry_interval] || 1
      @attempts = 0
    end

    def acquire
      @lock_id =  uuid.generate
      begin
        response = client.test_and_set(key, lock_id, value)
        @attempts = 0
        response
      rescue Exception => e  
        @attempts += 1
        raise LockAcqusitionFailure, e.message if attempts >= retries
        sleep retry_interval
        acquire
      end
    end

    def release
      begin
        response = client.test_and_set(key, value, lock_id)
      rescue Exception => e
        raise LockReleaseFailure, e.message
      end
    end

    def uuid
      @uuid ||= UUID.new
    end
  end
end
