require 'functional_spec_helpers'

describe "Etcd watch" do

  it "without index, returns the value at a particular index" do
    key = random_key(4)
    value1 = uuid.generate
    value2 = uuid.generate

    index1 = client.create(key, value1).node.modifiedIndex
    index2 = client.test_and_set(key, value2, value1).node.modifiedIndex

    expect(client.watch(key, index: index1).node.value).to eq(value1)
    expect(client.watch(key, index: index2).node.value).to eq(value2)
  end

  it "with index, waits and return when the key is updated" do
    response = nil
    key = random_key
    value = uuid.generate
    thr = Thread.new do
      response = client.watch(key)
    end
    client.set(key, value)
    thr.join
    expect(response.node.value).to eq(value)
  end
end
