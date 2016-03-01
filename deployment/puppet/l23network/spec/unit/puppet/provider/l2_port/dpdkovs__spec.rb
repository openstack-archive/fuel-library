require 'spec_helper'

describe Puppet::Type.type(:l2_port).provider(:dpdkovs) do
  let(:resource_br1) {
    Puppet::Type.type(:l2_bridge).new(
      :provider => 'ovs',
      :name     => 'br1',
      :bridge   => 'br1',
      :vendor_specific => {
          :datapath_type => 'netdev',
      }
    )
  }
  let(:provider_br1) { resource_br1.provider }

  let(:resource_port) {
    Puppet::Type.type(:l2_port).new(
      :provider => 'dpdkovs',
      :bridge   => 'br1',
      :name     => 'eth0',
    )
  }
  let(:provider_port) { resource_port.provider }

  let(:dpdk_ports_mapping) {
    {
      'eth0' => 'dpdk0'
    }
  }

  describe "ovs port" do
    before(:each) do
      puppet_debug_override()
      provider_br1.class.stubs(:vsctl).with(['add-br', 'br1', '--', 'set', 'Bridge', 'br1', 'datapath_type=netdev']).returns(true)
      provider_br1.class.stubs(:vsctl).with('set', 'Bridge', 'br1', 'stp_enable=false').returns(true)
      provider_br1.class.stubs(:interface_up).with('br1').returns(true)
    end

    it "Create bridge and add physical port to it" do
      provider_br1.create
      provider_br1.flush
      provider_port.class.stubs(:vsctl).with(['--may-exist', 'add-port', 'br1', 'dpdk0', '--', 'set', 'Interface', 'dpdk0', 'type=dpdk']).returns(true)
      provider_port.class.stubs(:get_dpdk_ports_mapping).returns(dpdk_ports_mapping)
      provider_port.create
    end
  end
end
