require 'spec_helper'

describe Etcd::Client do

  before(:all) do
    start_daemon(3)
  end

  after(:all) do
    stop_daemon
  end

  let(:client) do
    etcd_client
  end

  it 'should return the leader address' do
    expect(client.leader).to_not be_nil
  end

  it '#machines' do
    expect(client.machines).to include('http://127.0.0.1:4001')
  end

  it '#version' do
    expect(client.version).to match(/^etcd v?0\.\d+\.\d+(\+git)?/)
  end

  it '#version_prefix' do
    expect(client.version_prefix).to eq('/v2')
  end

  context '#api_execute' do
    it 'should raise exception when non http methods are passed' do
      expect do
        client.api_execute('/v2/keys/x', :do)
      end.to raise_error
    end

    it 'should redirect api request when allow_redirect is set' do
      key = random_key
      value = uuid.generate
      resp = client.set(key, value: value)
      resp.node.key.should eql key
      resp.node.value.should eql value
      client.get(key).value.should eql resp.value
    end
  end

  context '#http header based metadata' do
    before(:all) do
      key = random_key
      value = uuid.generate
      @response = etcd_client.set(key, value: value)
    end

    it '#etcd_index' do
      expect(@response.etcd_index).to_not be_nil
    end

    it '#raft_index' do
      expect(@response.raft_index).to_not be_nil
    end

    it '#raft_term' do
      expect(@response.raft_term).to_not be_nil
    end
  end
end
