require 'spec_helper'

describe Puppet::Type.type(:l3_ifconfig).provider(:lnx) do

  let(:resource) {
    Puppet::Type.type(:l3_ifconfig).new(
      :name      => 'eth1',
      :interface => 'eth1',
      :ensure    => :present,
      :ipaddr    => 'none',
      :gateway   => :absent,
      :provider  => :lnx
    )
  }

  let(:provider_class) {
    Puppet::Type.type(:l3_ifconfig).provider(:lnx)
  }

  let(:provider) {
    prefetched_provider = provider_class.instances.first
    resource.provider = prefetched_provider if prefetched_provider
    resource.provider
  }

  before(:each) do
    puppet_debug_override()
    provider_class.stubs(:get_if_defroutes_mappings).with().returns({})
  end

  it "no existing IPs on the given NIC" do
    provider_class.stubs(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>[]}})
    provider.create
    provider_class.expects(:addr_flush).with('eth1', true)
    provider.flush
  end

  it "remove all existing IPs from the given NIC" do
    provider_class.stubs(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>['1.1.1.1/24', '2.2.2.2/25']}})
    provider.ipaddr = provider.resource[:ipaddr]  # emulate puppet works
    # all ipaddresses from interface should be removed
    provider_class.expects(:addr_flush).with('eth1', true)
    provider.flush
  end
end