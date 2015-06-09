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

provider_class = Puppet::Type.type(:neutron_agent_ovs).provider(:ini_setting)
describe provider_class do
  let(:resource ) do
    Puppet::Type::Neutron_agent_ovs.new({
      :name => 'DEFAULT/foo',
      :value => 'bar',
    })
  end

  let (:provider) { resource.provider }

  [ 'RedHat', 'Debian' ].each do |os|
    context "on #{os} with default setting" do
      it 'it should fall back to default and use ovs_neutron_plugin.ini' do
        Facter.fact(:operatingsystem).stubs(:value).returns("#{os}")
        expect(provider.section).to eq('DEFAULT')
        expect(provider.setting).to eq('foo')
        expect(provider.file_path).to eq('/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini')
      end
    end
  end

  context 'on Ubuntu with default setting' do
    it 'it should fall back to default and use ml2_conf.ini' do
      Facter.fact(:operatingsystem).stubs(:value).returns('Ubuntu')
      expect(provider.section).to eq('DEFAULT')
      expect(provider.setting).to eq('foo')
      expect(provider.file_path).to eq('/etc/neutron/plugins/ml2/ml2_conf.ini')
    end
  end
end
