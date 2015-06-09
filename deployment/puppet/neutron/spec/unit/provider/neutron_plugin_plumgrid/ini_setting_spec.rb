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

provider_class = Puppet::Type.type(:neutron_plugin_plumgrid).provider(:ini_setting)
describe provider_class do
  let(:resource ) do
    Puppet::Type::Neutron_plugin_plumgrid.new({
      :name => 'DEFAULT/foo',
      :value => 'bar',
    })
  end

  let (:provider) { resource.provider }

  [ 'RedHat', 'Debian' ].each do |os|
    context "on #{os} with default setting" do
      it 'it should fall back to default and use plumgrid.ini' do
        Facter.fact(:operatingsystem).stubs(:value).returns("#{os}")
        expect(provider.section).to eq('DEFAULT')
        expect(provider.setting).to eq('foo')
        expect(provider.file_path).to eq('/etc/neutron/plugins/plumgrid/plumgrid.ini')
      end
    end
  end
end
