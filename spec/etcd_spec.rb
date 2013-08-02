
require 'spec_helper'

describe Etcd do
  describe "#client" do
    it "should return a valid Etcd::Client object" do
      expect(Etcd.client).to be_a_kind_of(Etcd::Client)
    end
    it "should pass the same options to Etcd::Client initilizer" do
      opts = { :host => '10.10.10.10', :port=> 4001 }
      Etcd::Client.should_receive(:new).with(opts)
      Etcd.client(opts)
    end
  end
end
