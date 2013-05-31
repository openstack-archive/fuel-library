require 'puppet'
require 'puppet/type/nova_floating'
describe 'Puppet::Type.type(:nova_floating)' do
  before :each do
    @nova_floating = Puppet::Type.type(:nova_floating).new(:name => 'test_IP', :network => '192.168.1.2')
  end

  it 'should accept valid IP address' do
    @nova_floating[:network] = '192.168.1.1'
    @nova_floating[:network] == '192.168.1.1'
  end
  it 'should accept valid CIDR subnet' do
    @nova_floating[:network] = '192.168.1.0/24'
    @nova_floating[:network] == '192.168.1.0/24'
  end
  it 'should not accept masklen more 2 didits' do
    expect {
      @nova_floating[:network] = '192.168.1.0/245'
    }.to raise_error(Puppet::Error, /Invalid value/)
  end
  it 'should not accept invalid ensure values' do
    expect {
      @nova_floating[:network] = 'qweqweqweqwe'
    }.to raise_error(Puppet::Error, /Invalid value/)
  end
end