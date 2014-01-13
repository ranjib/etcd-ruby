# Encoding: utf-8

require 'spec_helper'

describe 'lock' do

  let(:client) do
    Etcd.client
  end

  it 'should be able to acquire a lock' do
    expect do
      client.acquire_lock('/my_lock',10)
    end.to_not raise_error
  end

  it 'should be able to renew a lock based on value' do
    client.acquire_lock('/my_lock1', 10, value: 123)
    expect do
      client.renew_lock('/my_lock1', 10, value: 123)
    end.to_not raise_error
  end

  it 'should be able to renew a lock based on index' do
    client.acquire_lock('/my_lock2', 10)
    index = client.get_lock('/my_lock2', field:'index')
    expect do
      client.renew_lock('/my_lock2', 10, index: index)
    end.to_not raise_error
  end

  it 'should be able to delete a lock based on value' do
    client.acquire_lock('/my_lock3', 10, value: 123)
    expect do
      client.delete_lock('/my_lock3', value: 123)
    end.to_not raise_error
  end

  it 'should be able to delete a lock based on index' do
    client.acquire_lock('/my_lock4', 10)
    index = client.get_lock('/my_lock4', field:'index')
    expect do
      client.delete_lock('/my_lock4', index: index)
    end.to_not raise_error
  end
end
