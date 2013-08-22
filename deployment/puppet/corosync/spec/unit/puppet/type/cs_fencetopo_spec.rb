require 'spec_helper'

describe Puppet::Type.type(:cs_fencetopo) do
  subject do
    Puppet::Type.type(:cs_fencetopo)
  end

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
    }
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

  it "should have a 'name' parameter" do
    subject.new(:name => 'mock_resource')[:name].should == 'mock_resource'
  end

  describe "basic structure" do
    it "should be able to create a singleton instance" do
      provider_class = Puppet::Type::Cs_fencetopo.provider(Puppet::Type::Cs_fencetopo.providers[0])
      Puppet::Type::Cs_fencetopo.expects(:defaultprovider).returns(provider_class)

      subject.new(:name => "mock_resource").should_not be_nil
    end

    #it "should not be able to create other instances" do
      #TODO verify if fencetopo has a singleton nature
    #end

    [:cib, :name ].each do |param|
      it "should have a #{param} parameter" do
        subject.validparameter?(param).should be_true
      end

      it "should have documentation for its #{param} parameter" do
        subject.paramclass(param).doc.should be_instance_of(String)
      end
    end

    [ :nodes, :fence_topology ].each do |prop|
      it "should have a #{prop} property" do
        subject.validproperty?(prop).should be_true
      end

      it "should have documentation for its #{prop} property" do
        subject.propertybyname(prop).doc.should be_instance_of(String)
      end
    end
  end

  describe "when autorequiring resources" do

    before :each do
      @shadow = Puppet::Type.type(:cs_shadow).new(:name => 'myfencetopo',:cib=>'myfencetopo')
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource @shadow
    end

    it "should autorequire the corresponding resources" do

      @resource = described_class.new(
        :name=>'dummy',
        :cib=>'myfencetopo',
        :provider=>:crm,
        :ensure=>:present,
        :nodes=>$nodes,
        :fence_topology=>$fence_topology)

      @catalog.add_resource @resource
      req = @resource.autorequire
      req.size.should == 1
      #rewrite this f*cking should method of property type by the ancestor method
      [req[0].target,req[0].source].each do |instance|
        class << instance
          def should(*args)
            Object.instance_method(:should).bind(self).call(*args)
          end
        end
      end
      req[0].target.should eql(@resource)
      req[0].source.should eql(@shadow)
    end
  end
end
