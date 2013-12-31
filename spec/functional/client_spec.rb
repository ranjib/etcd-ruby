require 'functional_spec_helpers'

describe "Functional Test Suite" do

  it "#set/#get" do
    key = random_key
    value = uuid.generate
    client.set(key, value)
    expect(client.get(key).value).to eq(value)
  end

  it "#leader" do
    expect(etcd_servers).to include(client.leader)
  end

  it "#machines" do
    expect(client.machines).to include('http://127.0.0.1:4001')
  end
end
