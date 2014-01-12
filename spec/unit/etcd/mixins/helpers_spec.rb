require 'spec_helper'

shared_examples 'helper methods' do
  describe "#has_key" do
    it "should return true when the key is present" do
      client.should_receive(:get).with('/foo/bar').and_return({})
      expect(client.has_key?('/foo/bar')).to be_true
    end
    it "should return false when the key is absent" do
      client.should_receive(:get).with('/foo/bar').and_raise(Etcd::KeyNotFound)
      expect(client.has_key?('/foo/bar')).to be_false
    end
  end
end
