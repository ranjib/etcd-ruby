require 'spec_helper'

describe Etcd::Keys do

  it "#set/#get" do
    key = random_key
    value = uuid.generate
    client.set(key, value)
    expect(client.get(key).value).to eq(value)
  end

  it "should return the leade's address" do
    expect(client.leader).to_not be_nil
  end

  it "#machines" do
    expect(client.machines).to include('http://127.0.0.1:4001')
  end

  context "#http header based metadata" do
    before(:all) do
      key = random_key
      value = uuid.generate
      @response = client.set(key,value)
    end

    it "#etcd_index" do
      expect(@response.etcd_index).to_not be_nil
    end

    it "#raft_index" do
      expect(@response.raft_index).to_not be_nil
    end

    it "#raft_term" do
      expect(@response.raft_term).to_not be_nil
    end
  end
end
