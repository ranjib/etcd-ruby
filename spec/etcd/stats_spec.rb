# Encoding: utf-8

require 'spec_helper'

describe Etcd::Stats do

  let(:client) do
    Etcd.client
  end

  describe 'of leader' do

    let(:stats) do
      client.stats(:leader)
    end

    it 'should contain a key for leader' do
      expect(stats['leader']).to_not be_nil
    end

    it 'should have 4 followers (since we spawn 5 node etcd cluster)' do
      expect(stats['followers'].keys.size).to eq(4)
    end
  end

  it 'should show self statsistics' do
    expect(client.stats(:self)['name']).to_not be_nil
    expect(client.stats(:self)['state']).to_not be_nil
  end

  it 'should show store statistics' do
    expect(client.stats(:store).keys).to_not be_empty
  end

  it 'should raise error for invalid types' do
    expect do
      client.stats(:foo)
    end.to raise_error
  end
end
