require 'spec_helper'

describe Puppet::Type.type(:cs_commit) do
  subject do
    Puppet::Type.type(:cs_commit)
  end

  it "should have a 'name' parameter" do
    subject.new(:name => "mock_resource")[:name].should == "mock_resource"
  end

  describe "basic structure" do
    it "should be able to create an instance" do
      provider_class = Puppet::Type::Cs_commit.provider(Puppet::Type::Cs_commit.providers[0])
      Puppet::Type::Cs_commit.expects(:defaultprovider).returns(provider_class)
      subject.new(:name => "mock_resource").should_not be_nil
    end

    [:name ].each do |param|
      it "should have a #{param} parameter" do
        subject.validparameter?(param).should be_true
      end

      it "should have documentation for its #{param} parameter" do
        subject.paramclass(param).doc.should be_instance_of(String)
      end
    end
  [:cib ].each do |property|
    it "should have a #{property} property" do
      subject.validproperty?(property).should be_true
    end

    it "should have documentation for its #{property} property" do
      subject.propertybyname(property).doc.should be_instance_of(String)
    end
  end

  end

  describe "when autorequiring resources" do

    before :each do
      @csresource_foo = Puppet::Type.type(:cs_resource).new(:name => 'p_foo', :cib=>'baz', :ensure => :present)
      @cslocation_foo = Puppet::Type.type(:cs_location).new(:name => 'l_foo', :cib=>'baz',:ensure => :present)
      @csorder_foo = Puppet::Type.type(:cs_order).new(:name => 'o_foo', :cib=>'baz',:ensure => :present)
      @cscolocation_foo = Puppet::Type.type(:cs_colocation).new(:name => 'c_foo', :cib=>'baz',:ensure => :present)
      @csgroup_foo = Puppet::Type.type(:cs_group).new(:name => 'g_foo', :cib=>'baz',:ensure => :present)
      @csproperty_foo = Puppet::Type.type(:cs_property).new(:name => 'pr_foo', :cib=>'baz',:ensure => :present)
      @shadow = Puppet::Type.type(:cs_shadow).new(:name => 'baz',:cib=>"baz")
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource @cslocation_foo,@csresource_foo,@csproperty_foo,@csorder_foo,@cscolocation_foo,@csgroup_foo,@shadow
    end

    it "should autorequire the corresponding resources" do

      @resource=@shadow.generate[0]
      @catalog.add_resource @resource
      req = @resource.autorequire
      req.size.should == 7
      req.each do |e|
        #rewrite this f*cking should method of property type by the ancestor method
        class << e.target
          def should(*args)
            Object.instance_method(:should).bind(self).call(*args)
          end
        end
        e.target.should eql(@resource)
        [@cslocation_foo,@csresource_foo,@csproperty_foo,@csorder_foo,@cscolocation_foo,@csgroup_foo,@shadow].should include(e.source)
      end
    end

  end
end
