require 'functional_spec_helpers'

describe "Etcd read only client" do

  it "should not allow write" do
    key= random_key
    expect{
      read_only_client.set(key, uuid.generate)
    }.to raise_error(Net::HTTPRetriableError)
  end

  it "should allow reads" do
    key = random_key
    value = uuid.generate
    client.set(key, value)
    sleep 1
    expect(read_only_client.get(key).value).to eq(value)
  end

  it "should allow watch" do
    key = random_key
    value = uuid.generate
    index = client.set(key, value).node.modified_index
    expect(read_only_client.watch(key, index: index).value).to eq(value)
  end
end

