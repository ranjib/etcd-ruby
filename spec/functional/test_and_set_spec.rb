shared_examples "test_and_set" do
  it "should pass when prev value is correct" do
    key = random_key(2)
    old_value = uuid.generate
    new_value = uuid.generate
    client.set(key, old_value)
    client.test_and_set(key, new_value, old_value)
    expect(client.get(key).value).to eq(new_value)
  end

  it "should fail when prev value is incorrect" do
    key = random_key(2)
    value = uuid.generate
    client.set(key, value)
    expect{ client.test_and_set(key, 10, 2)}.to raise_error(Net::HTTPServerException)
  end

  it "#create should succeed when the key is absent and update should fail" do
    key = random_key(2)
    value = uuid.generate
    expect {
      client.update(key, value)
    }.to raise_error
    expect {
      client.create(key, value)
    }.to_not raise_error
    expect(client.get(key).value).to eq(value)
  end

  it "#create should fail when the key is present and update should succeed" do
    key = random_key(2)
    value = uuid.generate
    client.set(key, 1)

    expect {
      client.create(key, value)
    }.to raise_error

    expect {
      client.update(key, value)
    }.to_not raise_error
  end
end

