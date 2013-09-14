$:<< "lib/"

require 'etcd'
require 'uuid'

ETCD_BIN = ENV['ETCD_BIN'] || './etcd/etcd'

require 'functional_spec_helpers'
require 'functional/lock_spec'
require 'functional/read_only_client_spec'
require 'functional/test_and_set_spec'
require 'functional/watch_spec'

include Etcd::FunctionalSpec::Helpers

describe "Functional Test Suite" do

  before(:all) do
    start_etcd_servers
  end

  let(:etcd_servers) do
    (1..5).map{|n| "http://127.0.0.1:700#{n}"}
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

 
  include_examples "read only client"
  include_examples "lock"
  include_examples "test_and_set"
  include_examples "watch"

  it "#set/#get" do
    key = random_key
    value = uuid.generate
    client.set(key, value)
    expect(client.get(key).value).to eq(value)
  end


  it "#leader" do
    expect(etcd_servers).to include(client.leader)
  end

  it "#machines" do
    expect(client.machines).to include('http://127.0.0.1:4001')
  end
end
