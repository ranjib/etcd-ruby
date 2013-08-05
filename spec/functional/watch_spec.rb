shared_examples "watch" do
  it "without index, returns the value at a particular index" do
    key = random_key(4)
    value1 = uuid.generate
    value2 = uuid.generate

    index1 = client.set(key, value1).index
    index2 = client.set(key, value2).index

    expect(client.watch(key, index1).value).to eq(value1)
    expect(client.watch(key, index2).value).to eq(value2)
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
    expect(response.value).to eq(value)
  end
end
