# Encoding: utf-8

require 'spec_helper'

describe "Etcd read only client" do

  let(:client) do
    Etcd.client
  end

  it "should not allow write" do
    key= random_key
    expect{
      read_only_client.set(key, value: uuid.generate)
    }.to raise_error(Net::HTTPRetriableError)
  end

  it "should allow reads" do
    key = random_key
    value = uuid.generate
    client.set(key, value: value)
    sleep 1
    expect(read_only_client.get(key).value).to eq(value)
  end

  it "should allow watch" do
    key = random_key
    value = uuid.generate
    index = client.set(key, value: value).node.modified_index
    expect(read_only_client.watch(key, index: index).value).to eq(value)
  end
end

