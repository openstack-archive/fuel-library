require File.join(File.dirname(__FILE__), '../../find_spec_utils.rb')
require 'puppet'
require 'puppet/type/nova_config'
describe 'Puppet::Type.type(:nova_config)' do
  before :each do
    @nova_config = Puppet::Type.type(:nova_config).new(:name => 'foo', :value => 'bar')
  end
  it 'should require a name' do
    expect { Puppet::Type.type(:nova_config).new({}) }.should raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'should not expect a name with whitespace' do
    expect { Puppet::Type.type(:nova_config).new(:name => 'f oo') }.should raise_error(Puppet::Error, /Invalid value/)
  end
  it 'should not require a value when ensure is absent' do
    Puppet::Type.type(:nova_config).new(:name => 'foo', :ensure => :absent)
  end
  it 'should require a value when ensure is present' do
    expect { Puppet::Type.type(:nova_config).new(:name => 'foo', :ensure => :present) }.should raise_error(Puppet::Error, 'Property value must be set when ensure is present')
  end
  it 'should accept a valid value' do
    @nova_config[:value] = 'bar'
    @nova_config[:value].should == 'bar'
  end
  it 'should not accept a value with whitespace' do
    expect { @nova_config[:value] = 'b ar' }.should raise_error(Puppet::Error, /Invalid value/)
  end
  it 'should accept valid ensure values' do
    @nova_config[:ensure] = :present
    @nova_config[:ensure].should == :present
    @nova_config[:ensure] = :absent
    @nova_config[:ensure].should == :absent
  end
  it 'should not accept invalid ensure values' do
    expect { @nova_config[:ensure] = :latest}.should raise_error(Puppet::Error, /Invalid value/)
  end
end
