require 'spec_helper'

describe Puppet::Type.type(:l2_patch).provider(:ovs) do
  # NOTE! for bridges ['br1', 'br2'] jack names will be ['p_39a440c1-0', 'p_39a440c1-1']


  let(:resource_br1) {
    Puppet::Type.type(:l2_bridge).new(
      :provider => 'ovs',
      :name     => 'br1',
      :bridge   => 'br1',
    )
  }
  let(:provider_br1) { resource_br1.provider }
  #let(:instance_br1_ovs) { provider_br1.class.instances }

  let(:resource_patch) {
    Puppet::Type.type(:l2_patch).new(
      :provider => 'ovs',
      :name     => 'patch__br1--br2',
      :bridges  => ['br1', 'br2'],
      :jacks    => ['p_39a440c1-0', 'p_39a440c1-1'],
      :vlan_ids => ['0', '0'],
    )
  }
  let(:provider_patch) { resource_patch.provider }
  #let(:instance_patch_ovs) { provider_patch.class.instances }

  describe "ovs-to-ovs patchcord" do

    let(:resource_br2) {
      Puppet::Type.type(:l2_bridge).new(
        :provider => 'ovs',
        :name     => 'br2',
        :bridge   => 'br2',
      )
    }
    let(:provider_br2) { resource_br2.provider }
    #let(:instance_br2_ovs) { provider_br2.class.instances }


    before(:each) do
      puppet_debug_override()
      provider_br1.class.stubs(:iproute)
      provider_br2.class.stubs(:iproute)
      provider_br1.class.stubs(:vsctl).with('add-br', 'br1').returns(true)
      provider_br2.class.stubs(:vsctl).with('add-br', 'br2').returns(true)
      provider_patch.class.stubs(:vsctl).with([
        '--may-exist', 'add-port', 'br1', 'p_39a440c1-0', '--', 'set', 'Interface', 'p_39a440c1-0', 'type=patch', 'option:peer=p_39a440c1-1'
      ]).returns(true)
      provider_patch.class.stubs(:vsctl).with([
        '--may-exist', 'add-port', 'br2', 'p_39a440c1-1', '--', 'set', 'Interface', 'p_39a440c1-1', 'type=patch', 'option:peer=p_39a440c1-0'
      ]).returns(true)
    end

    it "Just create two bridges and connect it by patchcord" do
      provider_br1.create
      provider_br2.create
      provider_patch.create
    end

  end

  describe "ovs-to-lnx patchcord" do

    let(:resource_br2) {
      Puppet::Type.type(:l2_bridge).new(
        :provider => 'lnx',
        :name     => 'br2',
        :bridge   => 'br2',
      )
    }
    let(:provider_br2) { resource_br2.provider }
    #let(:instance_br2_ovs) { provider_br2.class.instances }


    before(:each) do
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end
      provider_br1.class.stubs(:iproute)
      provider_br1.class.stubs(:vsctl).with('add-br', 'br1').returns(true)
      provider_br2.class.stubs(:iproute).with().returns(true)
      provider_br2.class.stubs(:iproute).with('link', 'set', 'up', 'dev', 'br2').returns(true)
      provider_br2.stubs(:brctl).with(['addbr', 'br2']).returns(true)
      provider_patch.class.stubs(:get_bridges_order_for_patch).with(['br1','br2']).returns(['br1','br2'])
      File.stubs(:directory?).with('/sys/class/net/br2/bridge').returns(true)
      provider_patch.class.stubs(:vsctl).with(
        '--may-exist', 'add-port', 'br1', 'p_39a440c1-0', '--', 'set', 'Interface', 'p_39a440c1-0', 'type=internal'
      ).returns(true)
      provider_patch.class.stubs(:get_lnx_port_bridges_pairs).with().returns({})
      provider_patch.stubs(:brctl).with(['addif', 'br2', 'p_39a440c1-0']).returns(true)
      provider_patch.class.stubs(:iproute).with('link', 'set', 'up', 'dev', 'p_39a440c1-0').returns(true)

    end

    it "Just create two bridges and connect it by patchcord" do
      provider_br1.create
      provider_br2.create
      provider_patch.create
    end

    it "Patch was connected to another bridge" do
      provider_br1.create
      provider_br2.create
      provider_patch.class.stubs(:get_lnx_port_bridges_pairs).with().returns({'p_39a440c1-0'=>{:bridge=>'br-lnx1', :br_type=>:lnx},})
      provider_patch.stubs(:brctl).with(['delif', 'br-lnx1', 'p_39a440c1-0']).returns(true)
      provider_patch.stubs(:brctl).with(['addif', 'br2', 'p_39a440c1-0']).returns(true)
      provider_patch.create
    end

  end

end
