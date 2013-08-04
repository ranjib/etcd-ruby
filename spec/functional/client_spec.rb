#get('/a')                 = {"action":"GET","key":"/a","value":"1","index":1}
##set('/a',1)               = {"action":"SET","key":"/a","value":"1","index":1,"newKey":true}
##watch('/a')               = {"action":"SET","key":"/a","value":"1","index":1,"prevValue":"FooBAr"}
##test_and_set('/a', 10, 1) = {"action":"SET","key":"/a","value":"1","index":1,"prevValue":"1"}
#require 'ostruct'

$:<< "lib/"

require 'etcd'

ETCD_BIN= ENV['ETCD_BIN'] || './etcd/bin/etcd'

require 'functional_spec_helpers'
include Etcd::FunctionalSpec::Helpers

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

  it "#set/#get" do
    client.set('/a/b/c', 1)
    expect(client.get('/a/b/c').value).to eq("1")
  end

  describe "test_and_set" do
    it "should pass when prev value is correct" do
      client.set('/a/b/d',1)
      expect(client.test_and_set('/a/b/d', 10, 1)).to_not be_nil
    end

    it "should fail when prev value is incorrect" do
      client.set('/a/b/d',1)
      expect{ client.test_and_set('/a/b/d', 10, 2)}.to raise_error(Net::HTTPServerException)
    end
  end

  describe "#watch" do
    it "without index, returns the value at a particular index" do
      client.set('/a/b/e', 1)
      client.set('/a/b/e', 2)
      client.set('/a/b/e', 3)
      client.set('/a/b/e', 4)
      current_index = client.get('/a/b/e').index
      expect(client.watch('/a/b/e', current_index - 1).value.to_i).to eq(3)
    end

    it "with index, waits and return when the key is updated" do
      pending
    end
  end

  it "#leader" do
    expect(client.leader).to eq('0.0.0.0:7001')
  end

  it "#machines" do
    expect(client.machines).to include('0.0.0.0:4001')
  end
end
