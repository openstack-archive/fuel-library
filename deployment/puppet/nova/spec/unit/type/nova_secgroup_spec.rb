require 'puppet'

describe Puppet::Type.type(:nova_secgroup) do
  before :each do
    @secgroup = Puppet::Type.type(:nova_secgroup).new(:name => 'test')
  end

  it 'should accept any description' do
    @secgroup[:description] = '123'
    expect(@secgroup[:description]).to eq('123')
  end

  it 'should use empty string description by default' do
    expect(@secgroup[:description]).to eq('')
  end

end
