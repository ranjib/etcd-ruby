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
end

