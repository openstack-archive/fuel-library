require 'spec_helper'

describe Puppet::Type.type(:l2_port).provider(:ovs) do

  let(:resource_br1) {
    Puppet::Type.type(:l2_bridge).new(
      :provider => 'ovs',
      :name     => 'br1',
      :bridge   => 'br1',
      :stp      => false
    )
  }
  let(:provider_br1) { resource_br1.provider }

  let(:resource_port) {
    Puppet::Type.type(:l2_port).new(
      :provider => 'ovs',
      :bridge   => 'br1',
      :name     => 'eth0',
    )
  }
  let(:provider_port) { resource_port.provider }

  let(:resource_int_port) {
    Puppet::Type.type(:l2_port).new(
      :provider => 'ovs',
      :bridge   => 'br1',
      :name     => 'int_port',
    )
  }
  let(:provider_int_port) { resource_int_port.provider }

  describe "ovs port" do

    before(:each) do
      puppet_debug_override()
      provider_br1.class.stubs(:vsctl).with(['add-br', 'br1']).returns(true).at_least(1)
      provider_br1.class.stubs(:vsctl).with('set', 'Bridge', 'br1', 'stp_enable=false').returns(true).at_least(1)
      provider_br1.create
      provider_br1.flush
    end

    it "Create bridge and add physical port to it" do
      File.stubs(:exist?).with('/sys/class/net/eth0').returns(true).at_least(1)
      provider_port.class.stubs(:addr_flush).with('eth0').returns(true).at_least(1)
      provider_port.class.stubs(:vsctl).with(['--may-exist', 'add-port', 'br1', 'eth0']).returns(true).at_least(1)
      provider_port.class.stubs(:vsctl).with('set', 'Port', 'eth0', 'tag=[]').returns(true).at_least(1)
      provider_port.class.stubs(:interface_up).with('eth0').returns(true).at_least(1)
      provider_port.create
      provider_port.flush
    end

    it "Create bridge and add internal port to it" do
      File.stubs(:exist?).with('/sys/class/net/int_port').returns(false).at_least(1)
      provider_int_port.class.stubs(:addr_flush).with('int_port').never
      provider_int_port.class.stubs(:vsctl).with(['--may-exist', 'add-port', 'br1', 'int_port', '--', 'set', 'Interface', 'int_port', 'type=internal']).returns(true).at_least(1)
      provider_port.class.expects(:vsctl).with('set', 'Port', 'int_port', 'tag=[]').returns(true).at_least(1)
      provider_port.class.expects(:interface_up).with('int_port').returns(true).at_least(1)
      provider_int_port.create
      provider_int_port.flush
    end

  end

end
