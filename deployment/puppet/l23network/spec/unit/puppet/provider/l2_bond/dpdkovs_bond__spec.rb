require 'spec_helper'

describe Puppet::Type.type(:l2_bond).provider(:dpdkovs) do

  let(:dpdk_ports_mapping) {
    {
      'enp1s0f0' => 'dpdk0',
      'enp1s0f1' => 'dpdk1'
    }
  }

  let(:resource) {
    Puppet::Type.type(:l2_bond).new(
      :name     => 'bond0',
      :bridge   => 'br-prv',
      :slaves   => ['enp1s0f0', 'enp1s0f1'],
      :provider => 'dpdkovs',
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
      puppet_debug_override()
      provider.class.stubs(:get_dpdk_ports_mapping).returns(dpdk_ports_mapping)
      provider.class.stubs(:vsctl).with('--may-exist', 'add-bond', 'br-prv', 'bond0', ['dpdk0', 'dpdk1'], ['--', 'set', 'Interface', 'dpdk0', 'type=dpdk', '--', 'set', 'Interface', 'dpdk1', 'type=dpdk']).returns(true)
    end

    it "Just create bond, which unify two NICs" do
      provider.create
      #provider.flush
    end

    it "Create bond and setup required properties" do
      provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'bond_mode=balance-slb').returns(true)
      provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'other_config:lacp_time=fast').returns(true)
      provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'bond_updelay=111').returns(true)
      provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'bond_downdelay=222').returns(true)
      provider.create
      provider.flush
    end

    it "Delete existing bond" do
      provider.class.expects(:vsctl).with('del-port', 'br-prv', 'bond0')
      provider.destroy
    end

  end

end


describe Puppet::Type.type(:l2_bond).provider(:dpdkovs) do

  let(:dpdk_ports_mapping) {
    {
      'enp1s0f0' => 'dpdk0',
      'enp1s0f1' => 'dpdk1',
      'enp1s0f2' => 'dpdk2',
    }
  }

  let(:resource) {
    Puppet::Type.type(:l2_bond).new(
      :provider => :dpdkovs,
      :name     => 'bond0',
      :bridge   => 'br-prv',
      :slaves   => ['enp1s0f0', 'enp1s0f1'],
      :bond_properties => {
        'mode'      => 'balance-slb',
        'lacp_rate' => 'fast',
        'updelay'   => 0,
        'downdelay' => 0,
      },
    )
  }

  let(:provider_class) {
    Puppet::Type.type(:l2_bond).provider(:dpdkovs)
  }

  let(:provider) {
    prefetched_provider = provider_class.instances.first
    resource.provider = prefetched_provider if prefetched_provider
    resource.provider
  }

  before(:each) do
    puppet_debug_override()
    provider_class.stubs(:get_dpdk_ports_mapping).returns(dpdk_ports_mapping)
  end

  it "Just change needed bond properties ( bond_mode and lacp_rate )" do
    provider_class.stubs(:ovs_vsctl).with(['-f json', 'list', 'port']).returns(['{"data":[[["uuid","fd022078-c30c-4e1c-8ff1-e12e36a7d4fc"],["set",[]],0,false,["set",[]],0,["map",[]],false,["uuid","8f347007-d5f2-4b34-bfd9-785cc359659d"],["set",[]],["set",[]],"patch-tun",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]],[["uuid","114b5b6c-ff22-42c4-bdb3-bbba31b763ee"],"64:6a:0e:e3:9f:42",0,false,["set",[]],0,["map",[]],false,["set",[["uuid","4acb3e5e-d144-4121-93ee-f28e57705a61"],["uuid","f207bef7-9597-46cf-a75a-e032e1c397c4"]]],["set",[]],["set",[]],"bond0",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]],[["uuid","17ae81dc-8575-4fb0-972e-ad3680fa6078"],["set",[]],0,false,["set",[]],0,["map",[]],false,["uuid","ee0ba3c8-cd19-47af-8af0-0a184928a746"],["set",[]],["set",[]],"br-bond",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]],[["uuid","ebd27817-a1d9-486f-b158-f296d1caf456"],["set",[]],0,false,["set",[]],0,["map",[]],false,["uuid","0a16958b-b3d2-4da5-aa85-9bc80cf26d2d"],["set",[]],["set",[]],"br-int",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]]],"headings":["_uuid","bond_active_slave","bond_downdelay","bond_fake_iface","bond_mode","bond_updelay","external_ids","fake_bridge","interfaces","lacp","mac","name","other_config","qos","statistics","status","tag","trunks","vlan_mode"]}'])
    provider_class.stubs(:ovs_vsctl).with(['get', 'interface', '4acb3e5e-d144-4121-93ee-f28e57705a61', 'name']).returns(['dpdk0'])
    provider_class.stubs(:ovs_vsctl).with(['get', 'interface', 'f207bef7-9597-46cf-a75a-e032e1c397c4', 'name']).returns(['dpdk1'])
    provider_class.stubs(:ovs_vsctl).with(['port-to-br', 'bond0']).returns(['br-prv'])

    provider.bond_properties = provider.resource[:bond_properties]  # emulate puppet works

    provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'bond_mode=balance-slb').returns(true)
    provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'other_config:lacp_time=fast').returns(true)
    provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'bond_updelay=0').never
    provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'bond_downdelay=0').never
    provider.flush
  end

  it "Change nothing" do
    provider_class.stubs(:ovs_vsctl).with(['-f json', 'list', 'port']).returns(['{"data":[[["uuid","fd022078-c30c-4e1c-8ff1-e12e36a7d4fc"],["set",[]],0,false,["set",[]],0,["map",[]],false,["uuid","8f347007-d5f2-4b34-bfd9-785cc359659d"],["set",[]],["set",[]],"patch-tun",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]],[["uuid","114b5b6c-ff22-42c4-bdb3-bbba31b763ee"],"64:6a:0e:e3:9f:42",0,false,"balance-slb",0,["map",[]],false,["set",[["uuid","4acb3e5e-d144-4121-93ee-f28e57705a61"],["uuid","f207bef7-9597-46cf-a75a-e032e1c397c4"]]],["set",[]],["set",[]],"bond0",["map",[["lacp_time","fast"]]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]],[["uuid","17ae81dc-8575-4fb0-972e-ad3680fa6078"],["set",[]],0,false,["set",[]],0,["map",[]],false,["uuid","ee0ba3c8-cd19-47af-8af0-0a184928a746"],["set",[]],["set",[]],"br-bond",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]],[["uuid","ebd27817-a1d9-486f-b158-f296d1caf456"],["set",[]],0,false,["set",[]],0,["map",[]],false,["uuid","0a16958b-b3d2-4da5-aa85-9bc80cf26d2d"],["set",[]],["set",[]],"br-int",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]]],"headings":["_uuid","bond_active_slave","bond_downdelay","bond_fake_iface","bond_mode","bond_updelay","external_ids","fake_bridge","interfaces","lacp","mac","name","other_config","qos","statistics","status","tag","trunks","vlan_mode"]}'])
    provider_class.stubs(:ovs_vsctl).with(['get', 'interface', '4acb3e5e-d144-4121-93ee-f28e57705a61', 'name']).returns(['dpdk0'])
    provider_class.stubs(:ovs_vsctl).with(['get', 'interface', 'f207bef7-9597-46cf-a75a-e032e1c397c4', 'name']).returns(['dpdk1'])
    provider_class.stubs(:ovs_vsctl).with(['port-to-br', 'bond0']).returns(['br-prv'])

    provider.bond_properties = provider.resource[:bond_properties]  # emulate puppet works

    provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'bond_mode=balance-slb').never
    provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'other_config:lacp_time=fast').never
    provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'bond_updelay=0').never
    provider.class.expects(:vsctl).with('--', 'set', 'Port', 'bond0', 'bond_downdelay=0').never
    provider.flush
  end


  it "Replace bond slave interface fails" do
    provider_class.stubs(:ovs_vsctl).with(['-f json', 'list', 'port']).returns(['{"data":[[["uuid","fd022078-c30c-4e1c-8ff1-e12e36a7d4fc"],["set",[]],0,false,["set",[]],0,["map",[]],false,["uuid","8f347007-d5f2-4b34-bfd9-785cc359659d"],["set",[]],["set",[]],"patch-tun",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]],[["uuid","114b5b6c-ff22-42c4-bdb3-bbba31b763ee"],"64:6a:0e:e3:9f:42",0,false,["set",[]],0,["map",[]],false,["set",[["uuid","4acb3e5e-d144-4121-93ee-f28e57705a61"],["uuid","f207bef7-9597-46cf-a75a-e032e1c397c4"]]],["set",[]],["set",[]],"bond0",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]],[["uuid","17ae81dc-8575-4fb0-972e-ad3680fa6078"],["set",[]],0,false,["set",[]],0,["map",[]],false,["uuid","ee0ba3c8-cd19-47af-8af0-0a184928a746"],["set",[]],["set",[]],"br-bond",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]],[["uuid","ebd27817-a1d9-486f-b158-f296d1caf456"],["set",[]],0,false,["set",[]],0,["map",[]],false,["uuid","0a16958b-b3d2-4da5-aa85-9bc80cf26d2d"],["set",[]],["set",[]],"br-int",["map",[]],["set",[]],["map",[]],["map",[]],["set",[]],["set",[]],["set",[]]]],"headings":["_uuid","bond_active_slave","bond_downdelay","bond_fake_iface","bond_mode","bond_updelay","external_ids","fake_bridge","interfaces","lacp","mac","name","other_config","qos","statistics","status","tag","trunks","vlan_mode"]}'])
    provider_class.stubs(:ovs_vsctl).with(['get', 'interface', '4acb3e5e-d144-4121-93ee-f28e57705a61', 'name']).returns(['dpdk0'])
    provider_class.stubs(:ovs_vsctl).with(['get', 'interface', 'f207bef7-9597-46cf-a75a-e032e1c397c4', 'name']).returns(['dpdk2'])
    provider_class.stubs(:ovs_vsctl).with(['port-to-br', 'bond0']).returns(['br-prv'])

    provider.slaves = provider.resource[:slaves]  # emulate puppet works

    expect {provider.flush}.to raise_error(Puppet::ExecutionFailure)
  end
end
