

$:<< "lib/"

require 'etcd'

ETCD_BIN='./etcd/bin/etcd'

describe "Functional Test Suite" do

  before(:all) do
    start_etcd_servers
  end

  after(:all) do
    stop_etcd_servers
  end

  let(:client) do
    Etcd.client
  end

  it "#set" do
    client.set('/a/b/c', 1)
    expect(client.get('/a/b/c').value).to eq("1")
  end

end

def start_etcd_servers
  command =  ETCD_BIN + " -c 4001 -s 7001" 
  @pid = spawn(command)
  puts "Etcd process id :#{@pid}"
  Process.detach(@pid)
  sleep 1
end

def stop_etcd_servers
  Process.kill("HUP", @pid)
end
