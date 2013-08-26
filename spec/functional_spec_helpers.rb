require 'uuid'

module Etcd
  module FunctionalSpec
    module Helpers
      def start_etcd_servers
        @tmpdir = Dir.mktmpdir
        pid = spawn_etcd_server(@tmpdir+'/leader')
        @pids =  Array(pid)
        puts "Etcd leader process id :#{@pid}"
        leader = '127.0.0.1:4001'    

        4.times do |n|
          client_port = 4002 + n
          server_port = 7002 + n
          pid = spawn_etcd_server(@tmpdir+client_port.to_s, client_port, server_port, leader)
          @pids << pid
        end
      end

      def stop_etcd_servers
        @pids.each do |pid|
          Process.kill("HUP", pid)
          puts "Killed #{pid}"
        end
        FileUtils.remove_entry_secure @tmpdir
      end

      def spawn_etcd_server(dir, client_port=4001, server_port=7001, leader = nil)
        command = if leader.nil?
                    ETCD_BIN + " -c 127.0.0.1:#{client_port} -s 127.0.0.1:#{server_port} -d #{dir}"
                  else
                    ETCD_BIN + " -c 127.0.0.1:#{client_port} -s 127.0.0.1:#{server_port} -C #{leader} -d #{dir}"
                  end
        puts command
        pid = spawn(command)
        Process.detach(pid)
        sleep 1
        pid
      end

      def uuid
        @uuid ||= UUID.new
      end

      def random_key(n=1)
        key=''
        n.times do
          key << '/'+ uuid.generate
        end
        key
      end
    end
  end
end
