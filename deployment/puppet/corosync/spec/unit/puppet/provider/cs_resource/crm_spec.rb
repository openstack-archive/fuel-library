require 'spec_helper'

describe Puppet::Type.type(:cs_resource).provider(:crm) do

  let(:resource) { Puppet::Type.type(:cs_resource).new(:name => 'myresource', :provider=> :crm ) }
  let(:provider) { resource.provider }

  describe "#create" do
    before(:each) do
      provider.class.stubs(:exec_withenv).returns(0)
    end

    it "should create resource with corresponding members" do
      provider.class.stubs(:prefetch)
      resource[:primitive_type] = "Dummy"
      resource[:provided_by] = "pacemaker"
      resource[:primitive_class] = "ocf"
      resource[:operations] =  {"monitor"=>{"interval"=>"20"}}
      tmpfile = StringIO.new()
      Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
      tmpfile.stubs(:path)
      tmpfile.expects(:write).with("primitive myresource ocf:pacemaker:Dummy op monitor interval=20  ")
      provider.class.prefetch({})
      provider.create
      provider.flush
    end

    it "should stop and rename resource when only msname changes" do
      provider.instance_eval{
        @property_hash = {
          :name => :myresource,
          :provided_by=>"pacemaker",
          :ensure=>:present,
          :parameters=>{},
          :primitive_class=>"ocf",
          :primitive_type=>"Dummy",
          :metadata=>{},
          :ms_metadata=>{},
          :multistate_hash =>{:name=>"master_myresource",:type=>'master'},
          :provider=>:crm }
      }
      resource[:cib] = "shadow"
      resource[:primitive_type] = "Dummy"
      resource[:provided_by] = "pacemaker"
      resource[:primitive_class] = "ocf"
      resource[:operations] =  {"monitor"=>{"interval"=>"20"}}
      resource[:multistate_hash] = {"name"=>"SupER_Master","type"=>'master'}
      provider.expects(:crm).with('resource', 'stop', 'master_myresource')
      provider.expects(:try_command).with('rename','master_myresource', 'SupER_Master')
      provider.expects(:try_command).with('rename','master_myresource', 'SupER_Master','shadow')
      provider.multistate_hash={:name=>"SupER_Master",:type=>'master'}
      provider.instance_eval{@property_hash[:multistate_hash]}.should eql({:name=>"SupER_Master",:type=>'master'})
    end

    it "should stop and delete resource when mstype changes" do
      provider.instance_eval{
        @property_hash = {
          :name => :myresource,
          :provided_by=>"pacemaker",
          :ensure=>:present,
          :parameters=>{},
          :primitive_class=>"ocf",
          :primitive_type=>"Dummy",
          :metadata=>{},
          :ms_metadata=>{},
          :multistate_hash =>{:name=>"master_myresource",:type=>'master'},
          :provider=>:crm }
      }
      resource[:cib] = "shadow"
      resource[:primitive_type] = "Dummy"
      resource[:provided_by] = "pacemaker"
      resource[:primitive_class] = "ocf"
      resource[:operations] =  {"monitor"=>{"interval"=>"20"}}
      resource[:multistate_hash] = {"name"=>"SupER_Master","type"=>'master'}
      provider.expects(:crm).with('resource', 'stop', 'master_myresource')
      provider.expects(:try_command).with('delete','master_myresource')
      provider.expects(:try_command).with('delete','master_myresource', nil,'shadow')
      provider.multistate_hash={:name=>"SupER_Master",:type=>'clone'}
      provider.instance_eval{@property_hash[:multistate_hash]}.should eql({:name=>"SupER_Master",:type=>'clone'})
    end

  end

  describe "#destroy" do
    it "should destroy resource with corresponding name" do
      provider.expects(:try_command).with('delete','myresource')
      provider.expects(:crm).with('resource', 'stop', "myresource")
      provider.destroy
    end
  end

  describe "#instances" do
    it "should find instances" do
      provider.class.stubs(:block_until_ready).returns(true)
      out=File.open(File.dirname(__FILE__) + '/../../../../fixtures/cib/cib.xml')
      provider.class.stubs(:dump_cib).returns(out,nil)
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

