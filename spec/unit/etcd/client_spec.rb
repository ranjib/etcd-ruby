require 'spec_helper'
require 'unit/etcd/mixins/helpers_spec'

describe Etcd::Client do

  let(:client) do
    Etcd::Client.new
  end

  it "should use localhost and 4001 port by default" do
    expect(client.host).to eq('127.0.0.1')
    expect(client.port).to eq(4001)
  end

  it "shlould follow redirection by default" do
    expect(client.allow_redirect).to be_true
  end

  it "#machines should make /machines GET http request" do
    client.should_receive(:api_execute).with('/v1/machines', :get).and_return('foobar')
    expect(client.machines).to eq(['foobar'])
  end

  it "#leader should make /leader GET http request" do
    client.should_receive(:api_execute).with('/v1/leader', :get).and_return('foobar')
    expect(client.leader).to eq('foobar')
  end

  it "#get('/foo') should make /v1/keys/foo GET http request" do
    client.should_receive(:api_execute).with('/v1/keys/foo', :get).and_return('{"value":1}')
    expect(client.get('/foo').value).to eq(1)
  end

  describe "#set" do
    it "set('/foo', 1) should invoke /v1/keys/foo POST http request" do
      client.should_receive(:api_execute).with('/v1/keys/foo', :post, params: {'value'=>1}).and_return('{"value":1}')
      expect(client.set('/foo', 1).value).to eq(1)
    end
    it "set('/foo', 1, 4) should invoke /v1/keys/foo POST http request and set the ttl to 4" do
      client.should_receive(:api_execute).with('/v1/keys/foo', :post, params: {'value'=>1, 'ttl'=>4}).and_return('{"value":1}')
      expect(client.set('/foo', 1, 4).value).to eq(1)
    end
  end

  describe "#test_and_set" do
    it "test_and_set('/foo', 1, 4) should invoke /v1/keys/foo POST http request" do
      client.should_receive(:api_execute).with('/v1/keys/foo', :post, params: {'value'=>1, 'prevValue'=>4}).and_return('{"value":1}')
      expect(client.test_and_set('/foo', 1, 4).value).to eq(1)
    end
    it "test_and_set('/foo', 1, 4, 10) should invoke /v1/keys/foo POST http request and set the ttl to 10" do
      client.should_receive(:api_execute).with('/v1/keys/foo', :post, params: {'value'=>1, 'prevValue'=>4, 'ttl'=>10}).and_return('{"value":1}')
      expect(client.test_and_set('/foo', 1, 4, 10).value).to eq(1)
    end
  end

  it "#watch('/foo') should make /v1/watch/foo GET http request" do
    client.should_receive(:api_execute).with('/v1/watch/foo', :get, {timeout: 60}).and_return('{"value":1}')
    expect(client.watch('/foo').value).to eq(1)
  end

  it "#delete('/foo') should make /v1/keys/foo DELETE http request" do
    client.should_receive(:api_execute).with('/v1/keys/foo', :delete).and_return('{"index":"1"}')
    client.delete('/foo')
  end

  it_should_behave_like Etcd::Helpers
end
