# Encoding: utf-8

require 'spec_helper'

describe 'Etcd watch' do
  let(:client) do
    etcd_client
  end
  it 'without index, returns the value at a particular index' do
    key = random_key(4)
    value1 = uuid.generate
    value2 = uuid.generate

    index1 = client.create(key, value: value1).node.modifiedIndex
    index2 = client.test_and_set(key, value: value2, prevValue: value1).node.modifiedIndex

    expect(client.watch(key, index: index1).node.value).to eq(value1)
    expect(client.watch(key, index: index2).node.value).to eq(value2)
  end

  it 'with index, waits and return when the key is updated' do
    response = nil
    key = random_key
    value = uuid.generate
    thr = Thread.new do
      response = client.watch(key)
    end
    sleep 2
    client.set(key, value: value)
    thr.join
    expect(response.node.value).to eq(value)
  end


  it 'with recrusive, waits and return when the key is updated' do
    response = nil
    key = random_key
    value = uuid.generate
    client.set("#{key}/subkey", value:"initial_value")
    thr = Thread.new do
      response = client.watch(key, recursive:true, timeout:3)
    end
    sleep 2
    client.set("#{key}/subkey", value: value)
    thr.join
    expect(response.node.value).to eq(value)
  end
end
