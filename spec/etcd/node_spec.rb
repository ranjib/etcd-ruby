require 'spec_helper'

describe Etcd::Node do
  let(:client) do
    etcd_client
  end

  it 'should create a directory with parent key when nested keys are set' do
    parent = random_key
    child = random_key
    value = uuid.generate
    client.set(parent + child, value: value)
    expect(client.get(parent + child)).to_not be_directory
    expect(client.get(parent)).to be_directory
  end

  context '#children' do
    it 'should raise exception when invoked against a leaf node' do
      parent = random_key
      client.create(random_key, value: 10)
      expect do
        client.get(random_key).children
      end.to raise_error
    end
  end
end
