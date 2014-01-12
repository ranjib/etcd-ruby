require 'spec_helper'
require 'unit/etcd/mixins/helpers_spec'

describe Etcd::Client do

  let(:mock_json_data) do
    double(Net::HTTPSuccess, body: '{"node":{"value":1}}',:[] => nil)
  end

  let(:mock_text_data) do
    double(Net::HTTPSuccess, body: 'foobar', :[] => nil)
  end

  let(:client) do
    Etcd::Client.new
  end

  it "should use localhost and 4001 port by default" do
    expect(client.host).to eq('127.0.0.1')
    expect(client.port).to eq(4001)
  end

  it "should have SSL turned off by default" do
    expect(client.use_ssl).to be_false
  end

  it "should have SSL verification turned on by default" do
    expect(client.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
  end

  it "should follow redirection by default" do
    expect(client.allow_redirect).to be_true
  end

  it "#machines should make /machines GET http request" do
    client.should_receive(:api_execute).with('/v2/machines', :get).and_return(mock_text_data)
    expect(client.machines).to eq(['foobar'])
  end

  it "#leader should make /leader GET http request" do
    client.should_receive(:api_execute).with('/v2/leader', :get).and_return(mock_text_data)
    expect(client.leader).to eq('foobar')
  end

  it "#get('/foo') should make /v2/keys/foo GET http request" do
    client.should_receive(:api_execute).with('/v2/keys/foo', :get, {:params=>{}}).and_return(mock_json_data)
    expect(client.get('/foo').value).to eq(1)
  end

  describe "#set" do
    it "set('/foo', 1) should invoke /v2/keys/foo PUT http request" do
      client.should_receive(:api_execute).with('/v2/keys/foo', :put, params: {'value'=>1}).and_return(mock_json_data)
      expect(client.set('/foo', 1).value).to eq(1)
    end
    it "set('/foo', 1, 4) should invoke /v2/keys/foo PUT http request and set the ttl to 4" do
      client.should_receive(:api_execute).with('/v2/keys/foo', :put, params: {'value'=>1, 'ttl'=>4}).and_return(mock_json_data)
      expect(client.set('/foo', 1, 4).value).to eq(1)
    end
  end

  describe "#test_and_set" do
    it "test_and_set('/foo', 1, 4) should invoke /v2/keys/foo PUT http request" do
      client.should_receive(:api_execute).with('/v2/keys/foo', :put, params: {'value'=>1, 'prevValue'=>4}).and_return(mock_json_data)
      expect(client.test_and_set('/foo', 1, 4).node.value).to eq(1)
    end
    it "test_and_set('/foo', 1, 4, 10) should invoke /v2/keys/foo PUT http request and set the ttl to 10" do
      client.should_receive(:api_execute).with('/v2/keys/foo', :put, params: {'value'=>1, 'prevValue'=>4, 'ttl'=>10}).and_return(mock_json_data)
      expect(client.test_and_set('/foo', 1, 4, 10).node.value).to eq(1)
    end
  end

  it "#watch('/foo') should make /v2/watch/foo GET http request" do
    client.should_receive(:api_execute).with('/v2/keys/foo', :get, {:timeout=>60, :params=>{:wait=>true}}).and_return(mock_json_data)
    expect(client.watch('/foo').node.value).to eq(1)
  end

  it "#delete('/foo') should make /v2/keys/foo DELETE http request" do
    client.should_receive(:api_execute).with('/v2/keys/foo', :delete, {:params=>{}}).and_return(mock_json_data)
    client.delete('/foo')
  end

  it_should_behave_like 'helper methods'
end
