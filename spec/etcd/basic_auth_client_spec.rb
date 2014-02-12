# Encoding: utf-8

require 'spec_helper'

describe "Etcd basic auth client" do

  let(:client) do
    Etcd.client(:user_name => 'test', :password => 'pwd')
  end

  it '#user_name' do
    expect(client.user_name).to eq('test')
  end

  it '#password' do
    expect(client.password).to eq('pwd')
  end

  it "should set basic auth" do
    Net::HTTPRequest.any_instance.should_receive(:basic_auth).with('test', 'pwd') 
    key = random_key
    value = uuid.generate
    client.set(key, value: value)
    sleep 1
    expect(read_only_client.get(key).value).to eq(value)
  end
end
