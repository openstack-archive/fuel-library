require 'spec_helper'

describe Puppet::Type.type(:cs_fencetopo).provider(:crm) do

  $fence_topology = {
    'node-1.test.local' => {
      '1' => [
        'ipmi_reset',
      ],
      '2' => [
        'psu_off','psu_on'
      ],
    },
    'node-2.test.local' => {
      '1' => [
        'ilo_reset',
      ],
      '2' => [
        'psu_snmp_off','psu_snmp_on'
      ],
    },
  }
  $nodes = [ 'node-1.test.local', 'node-2.test.local' ]

  $foo_topology = {
    'node-1.foo-test.local' => {
      '1' => [
        'ipmi_off', 'dirac_off', 'ilo_off'
      ],
      '2' => [
        'psu1_off','psu2_off'
      ],
    },
    'node-2.foo-test.local' => {
      '1' => [
        'ipmi_off', 'dirac_off', 'ilo_off'
      ],
      '2' => [
        'psu1_off','psu2_off'
      ],
    },
    'node-3.foo-test.local' => {
      '1' => [
        'ipmi_off', 'dirac_off', 'ilo_off'
      ],
      '2' => [
        'psu1_off','psu2_off'
      ],
    },
  }
  $foo_nodes = [ 'node-1.foo-test.local', 'node-2.foo-test.local', 'node-3.foo-test.local' ]

 let(:resource) { Puppet::Type.type(:cs_fencetopo).new(
   :name=>'myfencetopo',
   :provider=>:crm,
   :ensure=>:present,
   :nodes=>$nodes,
   :fence_topology=>$fence_topology) }

 let(:provider) { resource.provider }
 let(:instance) { provider.class.instances }

 let(:foo_resource) { Puppet::Type.type(:cs_fencetopo).new(
   :name=>'myfootopo',
   :provider=>:crm,
   :ensure=>:present,
   :nodes=>$foo_nodes,
   :fence_topology=>$foo_topology) }

 let(:foo_provider) { foo_resource.provider }
 let(:foo_instance) { foo_provider.class.instances }

  describe "#create" do
    before(:each) do
      provider.class.stubs(:exec_withenv).returns(0)
    end

    it "should create topology singleton with corresponding nodes list and fence primitives" do
      provider.class.stubs(:block_until_ready).returns(true)
      provider.class.stubs(:instances).returns([])
      provider.expects(:exec_withenv).with(' --force configure fencing_topology node-1.test.local: stonith__ipmi_reset__node-1 stonith__psu_off__node-1,stonith__psu_on__node-1 node-2.test.local: stonith__ilo_reset__node-2 stonith__psu_snmp_off__node-2,stonith__psu_snmp_on__node-2 2>&1', {})
      provider.create
      provider.flush
    end

    it "should not try to recreate the same topology (idempotency test)" do
      provider.class.stubs(:block_until_ready).returns(true)
      provider.class.stubs(:instances).returns([instance])
      provider.create
      provider.flush
      instance.instance_eval{@property_hash}.should be_nil
    end

    it "should not create new topology, if one already exists (singleton test)" do
      foo_provider.class.stubs(:block_until_ready).returns(true)
      foo_provider.class.stubs(:instances).returns([instance])
      foo_provider.create
      foo_provider.flush
      foo_instance.instance_eval{@property_hash}.should be_nil
    end
  end

  describe "#destroy" do
    it "should destroy topology singleton" do
      expected = ''
      expected << ' --scope fencing-topology --delete-all --force --xpath //fencing-level 2>&1'
      expected << "\n"
      expected << " --delete --xml-text '<fencing-topology/>' 2>&1"
      provider.expects(:exec_withenv).with(expected, {})
      provider.destroy
    end
  end

  describe "#instances" do
    it "should find topology singleton" do
      provider.class.stubs(:block_until_ready).returns(true)
      out=File.open(File.dirname(__FILE__) + '/../../../../fixtures/cib/cib.xml')
      provider.class.stubs(:dump_cib).returns(out,nil)
      expected = {:name=>"myfencetopo", :fence_topology=>$fence_topology, :nodes=>$nodes, :ensure=>:present, :provider=>:crm}
      instance[0].instance_eval{@property_hash}.should eql(expected)
    end

    it "should not find topology singleton" do
      provider.class.stubs(:block_until_ready).returns(true)
      out=File.open(File.dirname(__FILE__) + '/../../../../fixtures/cib/cib_no_topo.xml')
      provider.class.stubs(:dump_cib).returns(out,nil)
      instance[0].instance_eval{@property_hash}.should be_nil
    end

  end

  describe '#exists?' do
    it 'checks if topology singleton exists' do
      provider.class.stubs(:block_until_ready).returns(true)
      out=File.open(File.dirname(__FILE__) + '/../../../../fixtures/cib/cib.xml')
      provider.class.stubs(:dump_cib).returns(out,nil)
      provider.class.stubs(:exec_withenv).with(' --query --scope fencing-topology', {}).returns(0)
      provider.exists?.should be_true
    end

    it 'checks if topology singleton does not exist' do
      provider.class.stubs(:block_until_ready).returns(true)
      out=File.open(File.dirname(__FILE__) + '/../../../../fixtures/cib/cib_no_topo.xml')
      provider.class.stubs(:dump_cib).returns(out,nil)
      provider.class.stubs(:exec_withenv).with(' --query --scope fencing-topology', {}).returns(6)
      provider.exists?.should be_false
    end
  end
end

