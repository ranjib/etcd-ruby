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

    def etcd_ports
      @pids.size.times.inject([]){|servers, n| servers << 4000 + n + 1 }
    end

    def start(numbers = 1)
      raise "Already running etcd servers(#{@pids.inspect})" unless @pids.empty?
      @tmpdir = Dir.mktmpdir
      (1..numbers).each do |n|
        @pids << daemonize(n, @tmpdir + n.to_s , numbers)
      end
      sleep 5
    end

    def daemonize(index, dir, total)
      ad_url = "http://localhost:#{7000 + index}"
      client_url = "http://localhost:#{4000 + index}"
      cluster_urls = (1..total).map{|n| "node_#{n}=http://localhost:#{7000 + n}"}.join(",")
      flags = " -name node_#{index} -initial-advertise-peer-urls #{ad_url}"
      flags << " -listen-peer-urls #{ad_url}"
      flags << " -listen-client-urls #{client_url}"
      flags << " -initial-cluster #{cluster_urls}"
      flags << " -data-dir #{dir} "

      command = etcd_binary + flags
      pid = spawn(command, out: '/dev/null', err: '/dev/null')
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
    def spawner
      Spawner.instance
    end
    def start_daemon(numbers = 1, opts={})
      spawner.start(numbers, opts)
    end

    def stop_daemon
     spawner.stop
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

    def etcd_client(port = 4001)
      Etcd.client(host: 'localhost', port: port)
    end

    def etcd_leader
      clients = spawner.etcd_ports.map{|port| etcd_client(port)}
      clients.detect{|c|c.stats(:self)['state'] == 'StateLeader'}
    end
  end
end

RSpec.configure do |c|
  c.include Etcd::SpecHelper
  c.before(:suite) do
    Etcd::Spawner.instance.start(3)
  end
  c.after(:suite) do
    Etcd::Spawner.instance.stop
  end
  c.fail_fast = false
end
