require 'spec_helper'

describe Etcd::Keys do

  shared_examples 'basic key operation' do

    it '#set/#get' do
      key = random_key
      value = uuid.generate
      client.set(key, value: value)
      expect(client.get(key).value).to eq(value)
    end

    context '#exists?' do
      it 'should be true for existing keys' do
        key = random_key
        client.create(key, value: 10)
        expect(client.exists?(key)).to be_true
      end
      it 'should be true for existing keys' do
        expect(client.exists?(random_key)).to be_false
      end
    end

    context 'directory' do
      it 'should be able to create a directory' do
        d = random_key
        client.create(d, dir: true)
        expect(client.get(d)).to be_true
      end
      context 'empty' do
        it 'should be able to delete with dir flag' do
          d = random_key
          client.create(d, dir: true)
          expect(client.delete(d, dir: true)).to be_true
        end

        it 'should not be able to delete without dir flag' do
          d = random_key
          client.create(d, dir: true)
          client.create("#{d}/foobar", value: 10)
          expect do
            client.delete(d)
          end.to raise_error(Etcd::NotFile)
        end
      end
      context 'not empty' do
        it 'should be able to delete with recursive flag' do
          d = random_key
          client.create(d, dir: true)
          client.create("#{d}/foobar")
          expect do
            client.delete(d, dir: true, recursive: true)
          end.to_not raise_error
        end
        it 'should be not able to delete without recursive flag' do
          d = random_key
          client.create(d, dir: true)
          client.create("#{d}/foobar")
          expect do
            client.delete(d, dir: true)
          end.to raise_error(Etcd::DirNotEmpty)
        end
      end
    end
  end

  context 'without ssl' do
    before(:all) do
      start_daemon
    end
    after(:all) do
      stop_daemon
    end
    let(:client) do
      etcd_client
    end
    it_should_behave_like 'basic key operation'
  end

  context 'with ssl' do
    before(:all) do
      start_daemon(1, use_ssl: true)
    end
    after(:all) do
      stop_daemon
    end
    let(:client) do
      etcd_ssl_client
    end
    it_should_behave_like 'basic key operation'
  end

  context 'with ssl and client certificate' do
    before(:all) do
      start_daemon(1, use_ssl: true, check_client_cert: true )
    end
    after(:all) do
      stop_daemon
    end
    let(:client) do
      etcd_ssl_client_with_cert
    end
    it_should_behave_like 'basic key operation'
  end
end
