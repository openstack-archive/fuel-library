require 'puppet'
require 'puppet/type/mongodb_shard'
describe Puppet::Type.type(:mongodb_shard) do

  before :each do
    @shard = Puppet::Type.type(:mongodb_shard).new(:name => 'test')
  end

  it 'should accept a shard name' do
    @shard[:name].should == 'test'
  end

  it 'should accept a member' do
    @shard[:member] = 'rs_test/mongo1:27017'
    @shard[:member].should == 'rs_test/mongo1:27017'
  end

  it 'should accept a keys array' do
    @shard[:keys] = [{'foo.bar' => {'name' => 1}}]
    @shard[:keys].should == [{'foo.bar' => {'name' => 1}}]
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:mongodb_shard).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

end
