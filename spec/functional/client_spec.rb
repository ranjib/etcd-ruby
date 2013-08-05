$:<< "lib/"

require 'etcd'
require 'uuid'

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


  let(:read_only_client) do
    Etcd.client(:allow_redirect=>false, :port=> 4004)
  end

  describe "read only client" do
    it "should not allow write" do
      key= random_key
      expect{
        read_only_client.set(key, uuid.generate)
      }.to raise_error(Net::HTTPRetriableError)
    end

    it "should allow reads" do
      key = random_key
      value = uuid.generate
      client.set(key, value)
      sleep 1
      expect(read_only_client.get(key).value).to eq(value)
    end

    it "should allow watch" do
      key = random_key
      value = uuid.generate
      index = client.set(key, value).index
      expect(read_only_client.watch(key, index).value).to eq(value)
    end
  end

  it "#set/#get" do
    key = random_key
    value = uuid.generate
    client.set(key, value)
    expect(client.get(key).value).to eq(value)
  end

  describe "test_and_set" do
    it "should pass when prev value is correct" do
      key = random_key(2)
      old_value = uuid.generate
      new_value = uuid.generate
      client.set(key, old_value)
      client.test_and_set(key, new_value, old_value)
      expect(client.get(key).value).to eq(new_value)
    end

    it "should fail when prev value is incorrect" do
      key = random_key(2)
      value = uuid.generate
      client.set(key, value)
      expect{ client.test_and_set(key, 10, 2)}.to raise_error(Net::HTTPServerException)
    end
  end


  describe "#watch" do
    it "without index, returns the value at a particular index" do
      key = random_key(4)
      value1 = uuid.generate
      value2 = uuid.generate

      index1 = client.set(key, value1).index
      index2 = client.set(key, value2).index

      expect(client.watch(key, index1).value).to eq(value1)
      expect(client.watch(key, index2).value).to eq(value2)
    end

    it "with index, waits and return when the key is updated" do
      response = nil
      key = random_key
      value = uuid.generate
      thr = Thread.new do
        response = client.watch(key)
      end
      client.set(key, value)
      thr.join
      expect(response.value).to eq(value)
    end
  end

  it "#leader" do
    expect(client.leader).to eq('0.0.0.0:7001')
  end

  it "#machines" do
    expect(client.machines).to include('0.0.0.0:4001')
  end
end
