require 'spec_helper'

describe Puppet::Type.type(:cs_resource).provider(:crm) do

  let(:resource) { Puppet::Type.type(:cs_resource).new(:name => 'myresource', :provider=> :crm ) }
  let(:provider) { resource.provider }

  describe "#create" do
    it "should create resource with corresponding members" do
      resource[:primitive_type] = "Dummy"
      resource[:provided_by] = "pacemaker"
      resource[:primitive_class] = "ocf"
      resource[:operations] =  {"monitor"=>{"interval"=>"20"}}
      provider.stubs(:crm)
      tmpfile = StringIO.new()
      Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
      tmpfile.stubs(:path)
      tmpfile.expects(:write).with("primitive myresource ocf:pacemaker:Dummy op monitor interval=20  ")
      provider.create
      provider.flush
    end
  end

  describe "#destroy" do
    it "should destroy resource with corresponding name" do
      provider.expects(:try_to_delete_resource).with('myresource')
      provider.expects(:crm).with('resource', 'stop', "myresource")
      provider.destroy
    end
  end

  describe "#instances" do
    it "should find instances" do
      provider.class.stubs(:block_until_ready).returns(true)
      provider.class.stubs(:ready).returns(true)
      out=File.open(File.dirname(__FILE__) + '/../../../../fixtures/cib/cib.xml')
      Puppet::Util::SUIDManager.expects(:run_and_capture).with(['/usr/sbin/crm','configure','show','xml']).returns(out,0)
      resources = []
      provider.class.instances.each do 
        |instance|
          resources << instance.instance_eval{@property_hash} 
      end
      
      resources[0].should eql(
    {:name=>:bar,:provided_by=>"pacemaker",:ensure=>:present,:parameters=>{},:primitive_class=>"ocf",:primitive_type=>"Dummy",:operations=>{"monitor"=>{"interval"=>"20"}},:metadata=>{},:ms_metadata=>{},:multistate_hash=>{},:provider=>:crm}
        )
    end
  end
end

