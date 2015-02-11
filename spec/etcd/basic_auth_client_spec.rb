# Encoding: utf-8

require 'spec_helper'

describe 'Etcd basic auth client' do
  let(:client) do
    Etcd.client(host: 'localhost') do |config|
      config.user_name = 'test'
      config.password = 'pwd'
    end
  end

  it '#user_name' do
    expect(client.user_name).to eq('test')
  end

  it '#password' do
    expect(client.password).to eq('pwd')
  end
end
