require 'etcd/node'
require 'json'

module Etcd

  class Response

    extend Forwardable

    attr_reader :action, :node

    def_delegators :@node, :key, :value

    def initialize(opts)
      @action = opts['action']
      @node = Node.new(opts['node'])
    end

    def self.from_json(json)
      Response.new(JSON.parse(json))
    end
  end
end
