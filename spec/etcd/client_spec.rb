require 'spec_helper'

describe Etcd::Client do
  let(:client) do
    etcd_client
  end

  it '#version' do #etcd 2.0.0-rc.1
    expect(client.version).to match(/^etcd v?\d+\.\d+\.\d+.*$/)
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
