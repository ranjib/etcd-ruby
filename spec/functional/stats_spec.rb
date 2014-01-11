
require 'functional_spec_helpers'

describe 'stats' do
  describe 'of leader' do

    let(:stats) do
      client.stats(:leader)
    end

    it 'should contain a key for leader' do
      expect(stats['leader']).to_not be_nil
    end

    it 'should have 4 followers (since we spawn 5 node etcd cluster)' do
      expect(stats['followers'].keys.size).to eq(4)
    end
  end

  it 'should show self statsistics' do
    expect(client.stats(:self)['name']).to_not be_nil
    expect(client.stats(:self)['leader']).to_not be_nil
  end

  it 'should show store statistics' do
    expect(client.stats(:store).keys.size).to_not be_empty
  end
end
