# Encoding: utf-8

require 'spec_helper'

describe 'Etcd test_and_set' do
  let(:client) do
    etcd_client
  end

  it 'should pass when prev value is correct' do
    key = random_key(2)
    old_value = uuid.generate
    new_value = uuid.generate
    resp = client.set(key, value: old_value)
    expect(resp.node.value).to eq(old_value)
    client.test_and_set(key, value: new_value, prevValue: old_value)
    expect(client.get(key).value).to eq(new_value)
  end

  it 'should fail when prev value is incorrect' do
    key = random_key(2)
    value = uuid.generate
    client.set(key, value: value)
    expect { client.test_and_set(key, value: 10, prevValue: 2) }.to raise_error(Etcd::TestFailed)
  end

  it '#create should succeed when the key is absent and update should fail' do
    key = random_key(2)
    value = uuid.generate
    expect do
      client.update(key, value: value)
    end.to raise_error
    expect do
      client.create(key, value: value)
    end.to_not raise_error
    expect(client.get(key).value).to eq(value)
  end

  it '#create should fail when the key is present and update should succeed' do
    key = random_key(2)
    value = uuid.generate
    client.set(key, value: 1)

    expect do
      client.create(key, value: value)
    end.to raise_error

    expect do
      client.update(key, value: value)
    end.to_not raise_error
  end
end
