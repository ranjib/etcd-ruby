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
    it "should not allow write"
    it "should allow reads"
    it "should allow watch"
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
      value1 = uuid.generate
      value2 = uuid.generate
      value3 = uuid.generate
      value4 = uuid.generate
      key = random_key(4)
      client.set(key, value1)
      client.set(key, value2)
      client.set(key, value3)
      client.set(key, value4)

      current_index = client.get(key).index
      expect(client.watch(key, current_index - 3).value).to eq(value1)
      expect(client.watch(key, current_index - 2).value).to eq(value2)
      expect(client.watch(key, current_index - 1).value).to eq(value3)
      expect(client.watch(key, current_index).value).to eq(value4)
    end

    it "with index, waits and return when the key is updated" do
      puts "watching a key.."
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
