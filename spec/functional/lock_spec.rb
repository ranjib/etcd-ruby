shared_examples "lock" do

  let(:other_client) do
    Etcd.client
  end

  it "if the lock is already aquired then another lock acquisition should fail" do
    key = random_key(4)
    value = uuid.generate
    # initialize the lock key
    client.set(key, value)
    thr = Thread.new do
      client.lock(:key=>key, :value=>value) do
        sleep 2
      end
    end
    sleep 1
    expect {
      other_client.lock(:key=>key, :value=> value) do
        puts "Do something"
      end
    }.to raise_error(Etcd::Lock::AcqusitionFailure)
    thr.join
  end

  it "if the lock is not already aquired then new lock aquisition should pass" do
    key = random_key(4)
    value = uuid.generate
    # initialize the lock key
    client.set(key, value)
    expect {
      client.lock(:key=>key, :value=>value) do
        :foo
      end
    }.to_not raise_error
  end

  it "should release the lock even if the given block raises exception" do
    key = random_key(4)
    value = uuid.generate
    client.set(key, value)
    expect {
      client.lock(:key=>key, :value=>value) do
        raise StandardError
      end
    }.to raise_error(StandardError)

    expect{
      other_client.lock(:key=>key, :value=>value) {}
    }.to_not raise_error
  end

  it "should raise lock release exception if the lock key value is changed " do
    key = random_key(4)
    value = uuid.generate
    # initialize the lock key
    client.set(key, value)
    thr = Thread.new do
      expect{
        client.lock(:key=>key, :value=>value) do
          sleep 3
        end
      }.to raise_error(Etcd::Lock::ReleaseFailure)

    end
    sleep 1
    other_client.set(key, uuid.generate)
    thr.join
  end
end
