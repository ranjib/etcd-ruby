require 'spec_helper'

describe Etcd::Log do
  it "should support debug, warn, info logging" do
    expect(Etcd::Log).to respond_to(:debug)
    expect(Etcd::Log).to respond_to(:warn)
    expect(Etcd::Log).to respond_to(:info)
  end
  it "should allow users to set a log levels" do
    Etcd::Log.level = :warn
    expect(Etcd::Log.level).to eq(:warn)
  end
end
