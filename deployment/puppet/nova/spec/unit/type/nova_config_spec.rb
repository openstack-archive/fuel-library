require 'puppet'
require 'puppet/type/nova_config'
describe 'Puppet::Type.type(:nova_config)' do
  before :each do
    @nova_config = Puppet::Type.type(:nova_config).new(:name => 'foo', :value => 'bar')
  end
  it 'should require a name' do
    expect {
      Puppet::Type.type(:nova_config).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'should not expect a name with whitespace' do
    expect {
      Puppet::Type.type(:nova_config).new(:name => 'f oo')
    }.to raise_error(Puppet::Error, /Invalid value/)
  end
  it 'should not require a value when ensure is absent' do
    Puppet::Type.type(:nova_config).new(:name => 'foo', :ensure => :absent)
  end
  it 'should require a value when ensure is present' do
    expect {
      Puppet::Type.type(:nova_config).new(:name => 'foo', :ensure => :present)
    }.to raise_error(Puppet::Error, /Property value must be set/)
  end
  it 'should accept a valid value' do
    @nova_config[:value] = 'bar'
    @nova_config[:value].should == 'bar'
  end
  it 'should not accept a value with whitespace' do
    @nova_config[:value] = 'b ar'
    @nova_config[:value].should == 'b ar'
  end
  it 'should accept valid ensure values' do
    @nova_config[:ensure] = :present
    @nova_config[:ensure].should == :present
    @nova_config[:ensure] = :absent
    @nova_config[:ensure].should == :absent
  end
  it 'should not accept invalid ensure values' do
    expect {
      @nova_config[:ensure] = :latest
    }.to raise_error(Puppet::Error, /Invalid value/)
  end
end
