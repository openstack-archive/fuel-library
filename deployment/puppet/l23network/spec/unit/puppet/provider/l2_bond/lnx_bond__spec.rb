require 'spec_helper'

describe Puppet::Type.type(:l2_bond).provider(:lnx) do

  let(:resource) {
    Puppet::Type.type(:l2_bond).new(
      :provider => :lnx,
      :name     => 'bond1',
      :slaves   => ['eth1', 'eth2'],
      :bond_properties => {
        'mode'             => '802.3ad',
        'lacp_rate'        => 'fast',
        'xmit_hash_policy' => 'layer2+3',
        'updelay'          => '111',
        'downdelay'        => '222',
        'ad_select'        => '2',
      },
    )
  }

  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances }

  describe "lnx bond" do
    before(:each) do
      puppet_debug_override()
      provider.class.stubs(:iproute).with('addr', 'flush', 'dev', 'eth1').returns(true)
      provider.class.stubs(:iproute).with('addr', 'flush', 'dev', 'eth2').returns(true)
    end

    it "Just create bond, which unify two NICs" do
      provider.create
      #provider.flush
    end

    it "Create bond and setup required properties" do
      provider.class.stubs(:set_sys_class).with('/sys/class/net/bonding_masters', '+bond1').returns(true)
      provider.class.stubs(:get_sys_class).with("/sys/class/net/bond1/bonding/slaves", true).returns([])
      provider.class.stubs(:set_sys_class).with('/sys/class/net/bond1/bonding/slaves', '+eth1').returns(true)
      provider.class.stubs(:set_sys_class).with('/sys/class/net/bond1/bonding/slaves', '+eth2').returns(true)
      provider.class.stubs(:set_interface_down).with('bond1').returns(true)
      provider.class.stubs(:set_interface_down).with('bond1', true).returns(true)
      provider.class.stubs(:set_interface_down).with('eth1').returns(true)
      provider.class.stubs(:set_interface_down).with('eth2').returns(true)
      provider.class.stubs(:get_sys_class).with('/sys/class/net/bond1/bonding/mode').returns('802.3ad')
      provider.class.stubs(:set_sys_class).with('/sys/class/net/bond1/bonding/mode', '802.3ad').returns(true)
      provider.class.stubs(:get_sys_class).with('/sys/class/net/bond1/bonding/xmit_hash_policy').returns('layer2')
      provider.class.stubs(:set_sys_class).with('/sys/class/net/bond1/bonding/xmit_hash_policy', 'layer2+3').returns(true)
      provider.class.stubs(:get_sys_class).with('/sys/class/net/bond1/bonding/lacp_rate').returns('slow')
      provider.class.stubs(:set_sys_class).with('/sys/class/net/bond1/bonding/lacp_rate', 'fast').returns(true)
      provider.class.stubs(:get_sys_class).with('/sys/class/net/bond1/bonding/ad_select').returns('stable')
      provider.class.stubs(:set_sys_class).with('/sys/class/net/bond1/bonding/ad_select', '2').returns(true)
      provider.class.stubs(:get_sys_class).with('/sys/class/net/bond1/bonding/updelay').returns('0')
      provider.class.stubs(:set_sys_class).with('/sys/class/net/bond1/bonding/updelay', '111').returns(true)
      provider.class.stubs(:get_sys_class).with('/sys/class/net/bond1/bonding/downdelay').returns('0')
      provider.class.stubs(:set_sys_class).with('/sys/class/net/bond1/bonding/downdelay', '222').returns(true)
      provider.class.stubs(:set_interface_up).with('bond1').returns(true)
      provider.class.stubs(:set_interface_up).with('eth1').returns(true)
      provider.class.stubs(:set_interface_up).with('eth2').returns(true)
      provider.create
      #leave here as template for future
      #provider.expects(:warn).with { |arg| arg =~ /lnx\s+don't\s+allow\s+change\s+bond\s+slaves/ }
      provider.flush
    end

    it "Delete existing bond" do
      provider.class.stubs(:set_sys_class).with('/sys/class/net/bonding_masters', '-bond1').returns(true)
      provider.destroy
    end

  end

end