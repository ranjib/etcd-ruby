# Encoding: utf-8

require 'spec_helper'

describe 'Etcd watch' do
  let(:client) do
    etcd_client
  end
  it 'without index, returns the value at a particular index' do
    key = random_key(4)
    value1 = uuid.generate
    value2 = uuid.generate

    index1 = client.create(key, value: value1).node.modifiedIndex
    index2 = client.test_and_set(key, value: value2, prevValue: value1).node.modifiedIndex

    expect(client.watch(key, index: index1).node.value).to eq(value1)
    expect(client.watch(key, index: index2).node.value).to eq(value2)
  end

  it 'with index, waits and return when the key is updated' do
    response = nil
    key = random_key
    value = uuid.generate
    thr = Thread.new do
      response = client.watch(key)
    end
    sleep 2
    client.set(key, value: value)
    thr.join
    expect(response.node.value).to eq(value)
  end

  it 'with recrusive, waits and return when the key is updated' do
    response = nil
    key = random_key
    value = uuid.generate
    client.set("#{key}/subkey", value:"initial_value")
    thr = Thread.new do
      response = client.watch(key, recursive:true, timeout:3)
    end
    sleep 2
    client.set("#{key}/subkey", value: value)
    thr.join
    expect(response.node.value).to eq(value)
  end

  context :eternal_watch do
    let(:key) { random_key }
    let(:value) { uuid.generate }

    it 'should loop multiple times collecting responses' do
      responses = []
      client.set(key, value: 'initial_value')

      thr = Thread.new do
        controlling_loop do |control|

          client.eternal_watch(key, timeout: 3) do |response_in_loop|
            responses << response_in_loop
          end

        end
      end

      sleep 2
      client.set(key, value: 'value-1')
      client.set(key, value: 'value-2')
      thr.join

      expect(responses.length).to eq 2
      expect(responses.map { |r| r.node.value }).to eq ['value-1', 'value-2']
    end

    it 'can watch recursive keys' do
      response = nil
      client.set("#{key}/subkey", value:"initial_value")

      thr = Thread.new do
        controlling_loop do |control|

          client.eternal_watch(key, recursive: true) do |response_in_loop|
            response = response_in_loop
            control.stop
          end

        end
      end

      sleep 2
      client.set("#{key}/subkey", value: value)
      thr.join

      expect(response.node.value).to eq(value)
    end

    it "resumes watching after the index of the last response" do
      responses = []
      client.set(key, value:"initial_value")

      thr = Thread.new do
        controlling_loop do |control|

          client.eternal_watch(key, timeout: 3) do |response_in_loop|
            responses << response_in_loop
            sleep 1
          end

        end
      end

      sleep 1
      client.set(key, value: 'value-1')
      client.set(key, value: 'value-2')
      thr.join

      expect(responses.length).to eq 2
      expect(responses.map { |r| r.node.value }).to eq ['value-1', 'value-2']
    end
  end

  private

  class LoopControl
    class Stop < Exception; end
    def stop
      raise Stop
    end
  end

  def controlling_loop
    control = LoopControl.new
    begin
      yield control
    rescue LoopControl::Stop, Net::ReadTimeout
    end
  end
end
