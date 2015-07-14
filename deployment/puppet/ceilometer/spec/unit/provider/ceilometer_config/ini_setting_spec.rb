$LOAD_PATH.push(
  File.join(
    File.dirname(__FILE__),
    '..',
    '..',
    '..',
    'fixtures',
    'modules',
    'inifile',
    'lib')
)

require 'spec_helper'

provider_class = Puppet::Type.type(:ceilometer_config).provider(:ini_setting)

describe provider_class do

  it 'should default to the default setting when no other one is specified' do
    resource = Puppet::Type::Ceilometer_config.new(
      {
        :name => 'DEFAULT/foo',
        :value => 'bar'
      }
    )
    provider = provider_class.new(resource)
    expect(provider.section).to eq('DEFAULT')
    expect(provider.setting).to eq('foo')
  end

  it 'should allow setting to be set explicitly' do
    resource = Puppet::Type::Ceilometer_config.new(
      {
        :name => 'dude/foo',
        :value => 'bar'
      }
    )
    provider = provider_class.new(resource)
    expect(provider.section).to eq('dude')
    expect(provider.setting).to eq('foo')
  end
end
