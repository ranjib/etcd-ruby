# Encoding: utf-8

module Etcd
  class Node
    include Comparable

    attr_reader :created_index, :modified_index, :expiration, :ttl, :key, :value
    alias_method :createdIndex, :created_index
    alias_method :modifiedIndex, :modified_index

    def initialize(opts = {})
      @created_index = opts['createdIndex']
      @modified_index = opts['modifiedIndex']
      @ttl = opts['ttl']
      @key = opts['key']
      @value = opts['value']
      @expiration = opts['expiration']
      @dir = opts['dir']

      if opts['dir'] and (!!opts['nodes'])
        opts['nodes'].each do |data|
          children << Node.new(data)
        end
      end
    end

    def <=>(other)
      key <=> other.key
    end

    def children
      if directory?
        @children ||= []
      else
        fail 'This is not a directory, cant have children'
      end
    end

    def directory?
      !! @dir
    end
  end
end
