require 'spec_helper'

describe Puppet::Type.type(:cs_order).provider(:crm) do

  let(:resource) { Puppet::Type.type(:cs_order).new(:name => 'myorder', :provider=> :crm ) }
  let(:provider) { resource.provider }

  describe "#create" do
    it "should create order with corresponding members" do
      resource[:first] = "p_1"
      resource[:second] = "p_2"
      resource[:score] = "inf"
      provider.class.stubs(:exec_withenv).returns(0)
      tmpfile = StringIO.new()
      Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
      tmpfile.stubs(:path)
      tmpfile.expects(:write).with("order myorder inf: p_1 p_2")
      provider.create
      provider.flush
    end
  end

  describe "#destroy" do
    it "should destroy order with corresponding name" do
      provider.expects(:crm).with('configure', 'delete', "myorder")
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
      instances[0].instance_eval{@property_hash}.should eql({:name=>"foo-before-bar",:score=>"INFINITY", :first=> 'foo',:second=>'bar', :ensure=>:present, :provider=>:crm})
    end
  end
end

