$LOAD_PATH.push(
  File.join(
    File.dirname(__FILE__),
    '..',
    '..',
    '..',
    'fixtures',
    'modules',
    'openstacklib',
    'lib')
)

require 'spec_helper'

provider_class = Puppet::Type.type(:glance_swift_config).provider(:ini_setting)

describe provider_class do

  it 'should default to the default setting when no other one is specified' do
    resource = Puppet::Type::Glance_swift_config.new(
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
    resource = Puppet::Type::Glance_swift_config.new(
      {
        :name => 'dude/foo',
        :value => 'bar'
      }
    )
    provider = provider_class.new(resource)
    expect(provider.section).to eq('dude')
    expect(provider.setting).to eq('foo')
  end

  it 'should ensure absent when <SERVICE DEFAULT> is specified as a value' do
    resource = Puppet::Type::Glance_swift_config.new(
      {:name => 'dude/foo', :value => '<SERVICE DEFAULT>'}
    )
    provider = provider_class.new(resource)
    provider.exists?
    expect(resource[:ensure]).to eq :absent
  end

  it 'should ensure absent when value matches ensure_absent_val' do
    resource = Puppet::Type::Glance_swift_config.new(
      {:name => 'dude/foo', :value => 'foo', :ensure_absent_val => 'foo' }
    )
    provider = provider_class.new(resource)
    provider.exists?
    expect(resource[:ensure]).to eq :absent
  end
end
