require 'puppet'
require 'mocha'
require 'spec_helper'

RSpec.configure do |config|
  config.mock_with :mocha
end

provider_class = Puppet::Type.type(:package).provider(:rdpkg)
describe provider_class do
  before :each do
    @res = Puppet::Type::Package.new(
      {
        :name => 'openvswitch-common',
        :source => 'http://10.20.0.2:8080/nsx',
      }
    )
    @provider = provider_class.new(@res)
  end
  it 'should change source parmeter if package exists' do
    @provider.stubs(:get_packages).returns(
    [ 'nicira-ovs-hypervisor-node_2.0.0.30176_all.deb',
      'openvswitch-common_2.0.0.30176_amd64.deb'
    ]
    )

    @provider.get_package_file('openvswitch-common','http://10.20.0.2:8080/nsx').should == 'openvswitch-common_2.0.0.30176_amd64.deb'
  end
end
