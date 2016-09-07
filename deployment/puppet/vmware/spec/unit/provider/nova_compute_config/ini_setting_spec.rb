require 'puppet'

require_relative '../../../../spec/fixtures/modules/inifile/lib/puppet/type/ini_setting'
require_relative '../../../../spec/fixtures/modules/inifile/lib/puppet/provider/ini_setting/ruby'
require_relative '../../../../lib/puppet/type/nova_compute_config'

provider_class = Puppet::Type.type(:nova_compute_config).provider(:ini_setting)
describe provider_class do

  it 'should default to the default setting when no other one is specified' do
    resource = Puppet::Type::Nova_compute_config.new(
      {:name => 'DEFAULT/foo', :value => 'bar'}
    )
    provider = provider_class.new(resource)
    expect(provider.section).to eq('DEFAULT')
    expect(provider.setting).to eq('foo')
  end

  it 'should allow setting to be set explicitly' do
    resource = Puppet::Type::Nova_compute_config.new(
      {:name => 'dude/foo', :value => 'bar'}
    )
    provider = provider_class.new(resource)
    expect(provider.section).to eq('dude')
    expect(provider.setting).to eq('foo')
  end
end
