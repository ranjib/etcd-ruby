# Encoding: utf-8

require 'spec_helper'

describe 'Etcd specs for the main etcd README examples' do
  let(:client) do
    etcd_client
  end

  shared_examples 'response with valid node data' do |action|
    if action == :delete
      it 'should not have value' do
        expect(@response.node.value).to be_nil
      end
    else
      it 'should set the value correctly' do
        expect(@response.node.value).to eq('PinkFloyd')
      end
    end
    if action == :create
      it 'should set the parent key correctly' do
        expect(@response.node.key).to match /^\/queue\/+/
      end
    else
      it 'should set the key properly' do
        expect(@response.node.key).to eq('/message')
      end
    end

    it 'modified index should be a positive integer' do
      expect(@response.node.created_index).to be > 0
    end

    it 'created index should be a positive integer' do
      expect(@response.node.modified_index).to be > 0
    end
  end

  shared_examples 'response with valid http headers' do

    it 'should have a positive etcd index (comes from http header)' do
      expect(@response.etcd_index).to be > 0
    end

    it 'should have a positive raft index (comes from http header)' do
      expect(@response.raft_index).to be > 0
    end

    it 'should have a positive raft term (comes from http header)' do
      expect(@response.raft_term).to be >= 0
    end
  end

  context 'set a key named "/message"' do

    before(:all) do
      @response = etcd_client.set('/message', value: 'PinkFloyd')
    end

    it_should_behave_like 'response with valid http headers'
    it_should_behave_like 'response with valid node data'

    it 'should set the return action to SET' do
      expect(@response.action).to eq('set')
    end
  end

  context 'get a key named "/message"' do

    before(:all) do
      etcd_client.set('/message', value: 'PinkFloyd')
      @response = etcd_client.get('/message')
    end

    it_should_behave_like 'response with valid http headers'
    it_should_behave_like 'response with valid node data'

    it 'should set the return action to GET' do
      expect(@response.action).to eq('get')
    end
  end

  context 'change the value of a key named "/message"' do

    before(:all) do
      etcd_client.set('/message', value: 'World')
      @response = etcd_client.set('/message', value: 'PinkFloyd')
    end

    it_should_behave_like 'response with valid http headers'
    it_should_behave_like 'response with valid node data'

    it 'should set the return action to SET' do
      expect(@response.action).to eq('set')
    end
  end

  context 'delete a key named "/message"' do

    before(:all) do
      etcd_client.set('/message', value: 'World')
      etcd_client.set('/message', value: 'PinkFloyd')
      @response = etcd_client.delete('/message')
    end

    it 'should set the return action to SET' do
      expect(@response.action).to eq('delete')
    end

    it_should_behave_like 'response with valid http headers'
    it_should_behave_like 'response with valid node data', :delete
  end

  context 'using ttl a key named "/message"' do

    before(:all) do
      etcd_client.set('/message', value: 'World')
      @set_time = Time.now
      @response = etcd_client.set('/message', value: 'PinkFloyd', ttl: 5)
    end

    it_should_behave_like 'response with valid http headers'
    it_should_behave_like 'response with valid node data'

    it 'should set the return action to SET' do
      expect(@response.action).to eq('set')
    end

    it 'should have valid expiration time' do
      expect(@response.node.expiration).to_not be_nil
    end

    it 'should have ttl available from the node' do
      expect(@response.node.ttl).to eq(5)
    end

    it 'should throw exception after the expiration time' do
      sleep 8
      expect do
        client.get('/message')
      end.to raise_error
    end

  end

  context 'waiting for a change against a key named "/message"' do

    before(:all) do
      etcd_client.set('/message', value: 'foo')
      thr = Thread.new do
        @response = etcd_client.watch('/message')
      end
      sleep 1
      etcd_client.set('/message', value: 'PinkFloyd')
      thr.join
    end

    it_should_behave_like 'response with valid http headers'
    it_should_behave_like 'response with valid node data'

    it 'should set the return action to SET' do
      expect(@response.action).to eq('set')
    end

    it 'should get the exact value by specifying a waitIndex' do
      client.set('/message', value: 'someshit')
      w_response = client.watch('/message', index: @response.node.modified_index)
      expect(w_response.node.value).to eq('PinkFloyd')
    end
  end

  context 'atomic in-order keys' do

    before(:all) do
      @response = etcd_client.create_in_order('/queue', value: 'PinkFloyd')
    end

    it_should_behave_like 'response with valid http headers'
    it_should_behave_like 'response with valid node data', :create

    it 'should set the return action to create' do
      expect(@response.action).to eq('create')
    end

    it 'should have the child key as a positive integer' do
      expect(@response.key.split('/').last.to_i).to be > 0
    end

    it 'should have the child keys as monotonically increasing' do
      first_response = client.create_in_order('/queue', value: 'The Jimi Hendrix Experience')
      second_response = client.create_in_order('/queue', value: 'The Doors')
      first_key = first_response.key.split('/').last.to_i
      second_key = second_response.key.split('/').last.to_i
      expect(first_key).to be < second_key
    end

    it 'should enlist all children in sorted manner' do
      responses = []
      10.times do |n|
        responses << client.create_in_order('/queue', value: 'Deep Purple - Track #{n}')
      end
      directory = client.get('/queue', sorted: true)
      past_index = directory.children.index(responses.first.node)
      9.times do |n|
        current_index = directory.children.index(responses[n + 1].node)
        expect(current_index).to be > past_index
        past_index = current_index
      end
    end
  end

  context 'directory with ttl' do

    before(:all) do
      @response = etcd_client.set('/directory', dir: true, ttl: 4)
    end

    it 'should create a directory' do
      expect(client.get('/directory')).to be_directory
    end

    it 'should have valid expiration time' do
      expect(client.get('/directory').node.expiration).to_not be_nil
    end

    it 'should have pre-designated ttl' do
      expect(client.get('/directory').node.ttl).to eq(4)
    end

    it 'will throw error if updated without setting prevExist' do
      expect do
        client.set('/directory', dir: true, ttl: 5)
      end.to raise_error
    end

    it 'can be updated by setting  prevExist to true' do
      client.set('/directory', prevExist: true, dir: true, ttl: 5)
      expect(client.get('/directory').node.ttl).to eq(5)
    end

    it 'watchers should get expriy notification' do
      client.set('/directory/a', value: 'Test')
      client.set('/directory', prevExist: true, dir: true, ttl: 2)
      response = client.watch('/directory/a', consistent: true, timeout: 3)
      expect(response.action).to eq('expire')
    end
    it 'should be expired after ttl' do
      sleep 5
      expect do
        client.get('/directory')
      end.to raise_error
    end
  end

  context 'atomic compare and swap' do

    it 'should  raise error if prevExist is passed a false' do
      client.set('/foo', value: 'one')
      expect do
        client.set('/foo', value: 'three',  prevExist: false)
      end.to raise_error
    end

    it 'should raise error is prevValue is wrong' do
      client.set('/foo', value: 'one')
      expect do
        client.set('/foo', value: 'three', prevValue: 'two')
      end.to raise_error
    end

    it 'should allow setting the value when prevValue is right' do
      client.set('/foo', value: 'one')
      expect(client.set('/foo', value: 'three', prevValue: 'one').value).to eq('three')
    end
  end
  context 'directory manipulation' do
    it 'should allow creating directory' do
      expect(client.set('/dir', dir: true)).to be_directory
    end

    it 'should allow listing directory' do
      client.set('/foo_dir/foo', value: 'bar')
      expect(client.get('/').children.map(&:key)).to include('/foo_dir')
    end

    it 'should allow recursive directory listing' do
      response = client.get('/', recursive: true)
      expect(response.children.find { |n|n.key == '/foo_dir' }.children).to_not be_empty
    end

    it 'should be able to delete empty directory without the recusrive flag' do
      expect(client.delete('/dir', dir: true).action).to eq('delete')
    end

    it 'should be able to delete directory with children with the recusrive flag' do
      expect(client.delete('/foo_dir', recursive: true).action).to eq('delete')
    end
  end

  context 'hidden nodes' do
    before(:all) do
      etcd_client.set('/_message', value: 'Hello Hidden World')
      etcd_client.set('/message', value: 'Hello World')
    end

    it 'should not be visible in directory listing' do
      expect(client.get('/').children.map(&:key)).to_not include('_message')
    end
  end
end
