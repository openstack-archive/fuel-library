require 'spec_helper'

describe Puppet::Type.type(:l2_bond).provider(:ovs) do

  let(:resource) {
    Puppet::Type.type(:l2_bond).new(
      :provider => :ovs,
      :name     => 'bond1',
      :bridge   => 'br1',
      :slaves   => ['eth1', 'eth2'],
      :bond_properties => {
        'mode'      => 'balance-slb',
        'lacp_rate' => 'fast',
        'updelay'   => 111,
        'downdelay' => 222,
      },
    )
  }

  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances }

  describe "ovs bond" do
    before(:each) do
      provider.class.stubs(:iproute)
      provider.class.stubs(:iproute).with('addr', 'flush', 'dev', 'eth1').returns(true)
      provider.class.stubs(:iproute).with('addr', 'flush', 'dev', 'eth2').returns(true)
      provider.class.stubs(:vsctl).with('--may-exist', 'add-bond', 'br1', 'bond1', ['eth1', 'eth2']).returns(true)
    end

    it "Just create bond, which unify two NICs" do
      provider.create
      #provider.flush
    end

    it "Create bond and setup required properties" do
      provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond1', 'bond_mode=balance-slb').returns(true)
      provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond1', 'other_config:lacp_time=fast').returns(true)
      provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond1', 'bond_updelay=111').returns(true)
      provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond1', 'bond_downdelay=222').returns(true)
      provider.create
      provider.expects(:warn).with { |arg| arg =~ /OVS\s+don't\s+allow\s+change\s+bond\s+slaves/ }
      provider.flush
    end

    it "Delete existing bond" do
      provider.class.expects(:vsctl).with('del-port', 'br1', 'bond1')
      provider.destroy
    end

  end

end