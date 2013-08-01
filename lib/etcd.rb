require 'etcd/client'
module Etcd
  def self.client(opts={})
    Etcd::Client.new(opts)
  end
end
