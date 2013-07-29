require 'spec_helper'

describe Puppet::Type.type(:cs_group).provider(:crm) do

  let(:resource) { Puppet::Type.type(:cs_group).new(:name => 'mygroup', :provider=> :crm ) }
  let(:provider) { resource.provider }

  describe "#create" do
    it "should create group with corresponding mebers" do
      resource[:primitives] = ["p_1", "p_2"]
      provider.class.stubs(:exec_withenv).returns(0)
      tmpfile = StringIO.new()
      Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
      tmpfile.stubs(:path)
      tmpfile.expects(:write).with("group mygroup p_1 p_2")
      provider.create
      provider.flush
    end
  end

  describe "#destroy" do
    it "should destroy group with corresponding name" do
      provider.expects(:crm).with('resource', 'stop', "mygroup")
      provider.expects(:crm).with('configure', 'delete', "mygroup")
      provider.destroy
      provider.flush
    end
  end

  describe "#instances" do
    it "should find instances" do
      provider.class.stubs(:block_until_ready).returns(true)
      out=File.open(File.dirname(__FILE__) + '/../../../../fixtures/cib/cib.xml')
      provider.class.stubs(:dump_cib).returns(out,nil)
      instances = provider.class.instances
      instances[0].instance_eval{@property_hash}.should eql({:name=>"mygroup", :primitives=> ['baz_1','baz_2'], :ensure=>:present, :provider=>:crm})
    end
  end
end

