require 'puppet'
require 'puppet/type/murano_paste_ini_config'
describe 'Puppet::Type.type(:murano_paste_ini_config)' do
  before :each do
    @murano_paste_ini_config = Puppet::Type.type(:murano_paste_ini_config).new(:name => 'DEFAULT/foo', :value => 'bar')
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:murano_paste_ini_config).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should not expect a name with whitespace' do
    expect {
      Puppet::Type.type(:murano_paste_ini_config).new(:name => 'f oo')
    }.to raise_error(Puppet::Error, /Parameter name failed/)
  end

  it 'should fail when there is no section' do
    expect {
      Puppet::Type.type(:murano_paste_ini_config).new(:name => 'foo')
    }.to raise_error(Puppet::Error, /Parameter name failed/)
  end

  it 'should not require a value when ensure is absent' do
    Puppet::Type.type(:murano_paste_ini_config).new(:name => 'DEFAULT/foo', :ensure => :absent)
  end

  it 'should accept a valid value' do
    @murano_paste_ini_config[:value] = 'bar'
    expect(@murano_paste_ini_config[:value]).to eq('bar')
  end

  it 'should not accept a value with whitespace' do
    @murano_paste_ini_config[:value] = 'b ar'
    expect(@murano_paste_ini_config[:value]).to eq('b ar')
  end

  it 'should accept valid ensure values' do
    @murano_paste_ini_config[:ensure] = :present
    expect(@murano_paste_ini_config[:ensure]).to eq(:present)
    @murano_paste_ini_config[:ensure] = :absent
    expect(@murano_paste_ini_config[:ensure]).to eq(:absent)
  end

  it 'should not accept invalid ensure values' do
    expect {
      @murano_paste_ini_config[:ensure] = :latest
    }.to raise_error(Puppet::Error, /Invalid value/)
  end
end
