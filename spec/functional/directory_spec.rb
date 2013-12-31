require 'functional_spec_helpers'

describe "Etcd directory node" do
  it "should create a directory with parent key when nested keys are set" do
    parent = random_key
    child = random_key
    value = uuid.generate
    client.set(parent+child, value)
    expect(client.get(parent+child)).to_not be_directory
    expect(client.get(parent)).to be_directory
  end
end
