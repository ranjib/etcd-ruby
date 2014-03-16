# Encoding: utf-8

require 'etcd/client'
##
# This module provides the Etcd:: name space for the gem and few
# factory methods for Etcd domain objects
module Etcd
  ##
  # Create and return a Etcd::Client object. It takes a hash +opts+
  # as an argument which gets passed to the Etcd::Client.new method
  # directly
  # If +opts+ is not passed default options are used, defined by Etcd::Client.new
  def self.client(opts = {})
    Etcd::Client.new(opts) do |config|
      yield config if block_given?
    end
  end
end
