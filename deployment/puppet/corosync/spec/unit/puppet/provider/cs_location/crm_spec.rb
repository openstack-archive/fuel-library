require 'spec_helper'

describe Puppet::Type.type(:cs_location).provider(:crm) do

  let(:resource) { Puppet::Type.type(:cs_location).new(:name => 'mylocation', :provider=> :crm ) }
  let(:provider) { resource.provider }

  describe "#create" do
    before(:each) do
      provider.class.stubs(:exec_withenv).returns(0)
    end

    it "should create location with corresponding members" do
      resource[:primitive] = "p_1"
      resource[:rules] = [
        {:score=> "inf",:expressions => [{:attribute=>"pingd",:operation=>"defined"}]}
      ]

      tmpfile = StringIO.new()
      Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
      tmpfile.stubs(:path)
      tmpfile.expects(:write).with("location mylocation p_1 rule inf: pingd defined")
      provider.create
      provider.flush
    end

    it "should create location with date_spec" do
      resource[:primitive] = "p_1"
      resource[:rules] = [
        {:score=> "inf",:date_expressions => [{:date_spec=>{:hours=>"10", :weeks=>"5"}, :operation=>"date_spec", :start=>"", :end=>""}]}
      ]

      tmpfile = StringIO.new()
      Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
      tmpfile.stubs(:path)
      tmpfile.expects(:write).with("location mylocation p_1 rule inf: date date_spec hours=10 weeks=5")
      provider.create
      provider.flush
    end

    it "should create location with lt" do
      resource[:primitive] = "p_1"
      resource[:rules] = [
        {:score=> "inf",:date_expressions => [{:operation=>"lt", :end=>"20131212",:start=>""}]}
      ]

      tmpfile = StringIO.new()
      Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
      tmpfile.stubs(:path)
      tmpfile.expects(:write).with("location mylocation p_1 rule inf: date lt 20131212")
      provider.create
      provider.flush
    end

    it "should create location with gt" do
      resource[:primitive] = "p_1"
      resource[:rules] = [
        {:score=> "inf",:date_expressions => [{:operation=>"gt", :end=>"",:start=>"20121212"}]}
      ]

      tmpfile = StringIO.new()
      Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
      tmpfile.stubs(:path)
      tmpfile.expects(:write).with("location mylocation p_1 rule inf: date gt 20121212")
      provider.create
      provider.flush

    end

    it "should create location with duration" do
      resource[:primitive] = "p_1"
      resource[:rules] = [
        {:score=> "inf",:date_expressions => [{:operation=>"in_range", :end=>"",:start=>"20121212", :duration=>{:weeks=>"5"}}]}
      ]

      tmpfile = StringIO.new()
      Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
      tmpfile.stubs(:path)
      tmpfile.expects(:write).with("location mylocation p_1 rule inf: date in_range start=20121212 weeks=5")
      provider.create
      provider.flush

    end

  end

  describe "#destroy" do
    it "should destroy location with corresponding name" do
      provider.expects(:crm).with('configure', 'delete', "mylocation")
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
      instances[0].instance_eval{@property_hash}.should eql(
      {:name=>"l_11",:rules=>[
        {:score=>"INFINITY",:boolean=>'',
        :expressions=>[
        {:attribute=>"#uname",:operation=>'ne',:value=>'ubuntu-1'}
        ],
        :date_expressions => [
        {:date_spec=>{:hours=>"10", :weeks=>"5"}, :operation=>"date_spec", :start=>"", :end=>""},
        {:operation=>"in_range", :start=>"20121212", :end=>"20131212"},
        {:operation=>"gt", :start=>"20121212",:end=>""},
        {:operation=>"lt", :end=>"20131212",:start=>""},
        {:operation=>"in_range", :start=>"20121212", :end=>"",:duration=>{:years=>"10"}}
        ]
        }
        ],
        :primitive=> 'master_bar', :node_score=>nil,:node=>nil, :ensure=>:present, :provider=>:crm})
      instances[1].instance_eval{@property_hash}.should eql(:name=>"l_12",:node_score=>"INFINITY",:node=>"ubuntu-1",:primitive=>"master_bar",:ensure=>:present,:provider=>:crm,:rules=>[])
    end
  end
end

