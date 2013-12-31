require 'etcd/node'
require 'json'

module Etcd

  class Response

    extend Forwardable

    attr_reader :action, :node, :etcd_index, :raft_index, :raft_term

    def_delegators :@node, :key, :value, :directory?, :children

    def initialize(opts, headers={})
      @action = opts['action']
      @node = Node.new(opts['node'])
      @etcd_index = headers[:etcd_index]
      @raft_index = headers[:raft_index]
      @raft_term = headers[:raft_term]
    end

    def self.from_http_response(response)
      data = JSON.parse(response.body)
      headers = Hash.new
      headers[:etcd_index] = response['X-Etcd-Index'].to_i
      headers[:raft_index] = response['X-Raft-Index'].to_i
      headers[:raft_term] = response['X-Raft-Term'].to_i
      response = Response.new(data, headers)
    end
  end
end
