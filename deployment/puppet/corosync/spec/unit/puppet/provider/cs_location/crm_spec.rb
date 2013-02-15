require 'spec_helper'

describe Puppet::Type.type(:cs_location).provider(:crm) do

  let(:resource) { Puppet::Type.type(:cs_location).new(:name => 'mylocation', :provider=> :crm ) }
  let(:provider) { resource.provider }

  describe "#create" do
    it "should create location with corresponding members" do
      resource[:primitive] = "p_1"
      resource[:rules] = [
        {:score=> "inf",:expressions => [{:attribute=>"pingd",:operation=>"defined"}]}
        ]
          
      provider.stubs(:crm)
      tmpfile = StringIO.new()
      Tempfile.stubs(:open).with("puppet_crm_update").yields(tmpfile)
      tmpfile.stubs(:path)
      tmpfile.expects(:write).with("location mylocation p_1 rule inf: pingd defined ")
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
      provider.class.stubs(:ready).returns(true)
      out=File.open(File.dirname(__FILE__) + '/../../../../fixtures/cib/cib.xml')
      Puppet::Util::SUIDManager.stubs(:run_and_capture).with(['/usr/sbin/crm','configure','show','xml']).returns(out,0)
      instances = provider.class.instances
      instances[0].instance_eval{@property_hash}.should eql(
        {:name=>"l_11",:rules=>[
          {:score=>"INFINITY",:boolean=>'',
            :expressions=>[
              {:attribute=>"#uname",:operation=>'ne',:value=>'ubuntu-1'}
                ],
            :date_expressions => [
              {:date_spec=>{:hours=>"10", :weeks=>"5"}, :operation=>"date_spec", :start=>"", :end=>""},
              {:date_spec=>{:weeks=>"5"}, :operation=>"date_spec", :start=>"", :end=>""}
                ]
           }
        ],
         :primitive=> 'master_bar', :node_score=>nil,:node=>nil, :ensure=>:present, :provider=>:crm})
    end
  end
end

