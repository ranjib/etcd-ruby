require 'spec_helper'

describe Etcd::Client do

  let(:client) do

    cert_file = File.expand_path('../../data/ca/certs/server.crt', __FILE__)
    key_file = File.expand_path('../../data/ca/private/server.key', __FILE__)
    ca_file = File.expand_path('../../data/ca/certs/ca.crt', __FILE__)
    chain = File.expand_path('../../data/ca/chain.crt', __FILE__)

    Etcd.client(host: 'localhost') do |config|
      config.use_ssl = true
      config.ca_file = ca_file
    end
  end

  it 'should return the leader address' do
    expect(client.leader).to_not be_nil
  end

  it '#machines' do
    expect(client.machines).to include('https://127.0.0.1:4001')
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
      rd_client = Etcd.client(host: 'localhost', port: 4003) do |config|
          config.use_ssl = true
          config.ca_file = File.expand_path('../../data/ca/certs/ca.crt', __FILE__)
          config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      resp = rd_client.set(key, value: value)
      resp.node.key.should eql key
      resp.node.value.should eql value
      client.get(key).value.should eql resp.value
    end
  end

  context '#http header based metadata' do
    before(:all) do
      key = random_key
      value = uuid.generate
      @response = other_client.set(key, value: value)
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
