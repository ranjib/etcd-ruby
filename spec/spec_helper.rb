# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
$LOAD_PATH.unshift(File.expand_path('../spec', __FILE__))

require 'coco'
require 'uuid'
require 'etcd'
require 'singleton'

module Etcd
  class Spawner

    include Singleton

    def initialize
      @pids = []
      @cert_file = File.expand_path('../data/server.crt', __FILE__)
      @key_file = File.expand_path('../data/server.key', __FILE__)
      @ca_cert = File.expand_path('../data/ca.crt', __FILE__)
    end

    def etcd_servers
      @pids.size.times.inject([]){|servers, n| servers << "http://127.0.0.1:700#{n}" }
    end

    def start(numbers = 1, opts={})
      raise "Already running etcd servers(#{@pids.inspect})" unless @pids.empty?
      @tmpdir = Dir.mktmpdir
      ssl_args = ""
      ssl_args << " -cert-file=#{@cert_file} -key-file=#{@key_file}" if opts[:use_ssl]
      ssl_args << " -ca-file=#{@ca_cert}" if opts[:check_client_cert]
      @pids << daemonize(@tmpdir, ssl_args)
      (numbers - 1).times do |n|
        @pids << daemonize(@tmpdir, ssl_args)
      end
    end

    def daemonize(dir, ssl_args)
      client_port = 4001 + @pids.size
      server_port = 7001 + @pids.size
      leader = '127.0.0.1:7001'
      args = " -addr 127.0.0.1:#{client_port} -peer-addr 127.0.0.1:#{server_port}"
      args << " -data-dir #{dir + client_port.to_s} -name node_#{client_port}"
      command = etcd_binary + args + ssl_args
      command << " -peers #{leader}"  unless @pids.empty? # if pids are not empty, theres a daemon already
      pid = spawn(command, out: '/dev/null')
      sleep 1
      Process.detach(pid)
      pid
    end

    def etcd_binary
      if File.exists? './etcd/bin/etcd'
        './etcd/bin/etcd'
      elsif !!ENV['ETCD_BIN']
        ENV['ETCD_BIN']
      else
        fail 'etcd binary not found., you need to set ETCD_BIN'
      end
    end

    def stop
      @pids.each do |pid|
        Process.kill('TERM', pid)
      end
      FileUtils.remove_entry_secure(@tmpdir, true)
      @pids.clear
    end
  end

  module SpecHelper

    def start_daemon(numbers = 1, opts={})
      Spawner.instance.start(numbers, opts)
    end

    def stop_daemon
      Spawner.instance.stop
    end

    def uuid
      @uuid ||= UUID.new
    end

    def random_key(n = 1)
      key = ''
      n.times do
        key << '/' + uuid.generate
      end
      key
    end

    def etcd_ssl_client
      Etcd.client(host: 'localhost') do |config|
        config.use_ssl = true
        config.ca_file = File.expand_path('../data/ca.crt', __FILE__)
      end
    end

    def etcd_ssl_client
      Etcd.client(host: 'localhost') do |config|
        config.use_ssl = true
        config.ca_file = File.expand_path('../data/ca.crt', __FILE__)
      end
    end

    def etcd_ssl_client_with_cert
      client_cert = File.expand_path('../data/client.crt', __FILE__)
      client_key = File.expand_path('../data/client.key', __FILE__)
      Etcd.client(host: 'localhost') do |config|
        config.use_ssl = true
        config.ca_file = File.expand_path('../data/ca.crt', __FILE__)
        config.ssl_cert = OpenSSL::X509::Certificate.new(File.read(client_cert))
        config.ssl_key = OpenSSL::PKey::RSA.new(File.read(client_key))
      end
    end

    def etcd_client
      Etcd.client
    end

    def read_only_client
      Etcd.client(allow_redirect: false, port: 4002, host: 'localhost')
    end
  end
end

RSpec.configure do |c|
  c.include Etcd::SpecHelper
end
