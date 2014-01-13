require 'spec_helper'

describe Etcd::Keys do

  let(:client) do
    Etcd.client
  end

  it '#set/#get' do
    key = random_key
    value = uuid.generate
    client.set(key, value)
    expect(client.get(key).value).to eq(value)
  end

  context '#exists?' do
    it 'should be true for existing keys' do
      key = random_key
      client.create(key, 10)
      expect(client.exists?(key)).to be_true
    end
    it 'should be true for existing keys' do
      expect(client.exists?(random_key)).to be_false
    end
  end
end
