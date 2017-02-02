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

  let(:resource_port_mtu) {
    Puppet::Type.type(:l2_port).new(
      :provider => 'dpdkovs',
      :bridge   => 'br1',
      :name     => 'eth0',
      :mtu      => '1504',
      :vendor_specific => {
        :driver => 'i40e',
      },
    )
  }

  let(:resource_port_multiq) {
    Puppet::Type.type(:l2_port).new(
      :provider => 'dpdkovs',
      :bridge   => 'br1',
      :name     => 'eth0',
      :vendor_specific => {
        :max_queues => '8',
      },
    )
  }

  let(:provider_port) { resource_port.provider }
  let(:provider_port_mtu) { resource_port_mtu.provider }
  let(:provider_port_multiq) { resource_port_multiq.provider }
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
      provider_br1.class.stubs(:vsctl).with('set', 'Port', 'br1', 'tag=[]').returns(true)
      provider_br1.class.stubs(:interface_up).with('br1').returns(true)
    end

    it "Create bridge and add physical port to it" do
      provider_br1.create
      provider_br1.flush
      provider_port.class.stubs(:vsctl).with(['--may-exist', 'add-port', 'br1', 'dpdk0', '--', 'set', 'Interface', 'dpdk0', 'type=dpdk']).returns(true)
      provider_port.class.stubs(:get_dpdk_ports_mapping).returns(dpdk_ports_mapping)
      provider_port.create
    end

    it "Create port with custom mtu" do
      provider_br1.create
      provider_br1.flush
      provider_port_mtu.class.stubs(:vsctl).with(['--may-exist', 'add-port', 'br1', 'dpdk0', '--', 'set', 'Interface', 'dpdk0', 'type=dpdk']).returns(true)
      provider_port_mtu.class.stubs(:get_dpdk_ports_mapping).returns(dpdk_ports_mapping)
      provider_port_mtu.create
      provider_port_mtu.class.stubs(:vsctl).with('set', 'Interface', 'dpdk0', 'mtu_request=1504').returns(true)
      provider_port_mtu.flush
    end

    it " Create port with multiq" do 
      provider_br1.create
      provider_br1.flush
      provider_port_multiq.class.stubs(:vsctl).with(['--may-exist', 'add-port', 'br1', 'dpdk0', '--', 'set', 'Interface', 'dpdk0', 'type=dpdk']).returns(true)
      provider_port_multiq.class.stubs(:get_dpdk_ports_mapping).returns(dpdk_ports_mapping)
      provider_port_multiq.create
      provider_port_multiq.class.stubs(:vsctl).with('set', 'Interface', 'dpdk0', 'options:n_rxq=8').returns(true)
      provider_port_multiq.flush
   end
  end
end
