require 'spec_helper'

describe Puppet::Type.type(:cs_rsc_location) do
  subject do
    Puppet::Type.type(:cs_rsc_location)
  end

  it "should have a 'name' parameter" do
    subject.new(:name => "mock_resource")[:name].should == "mock_resource"
  end

  describe "basic structure" do
    it "should be able to create an instance" do
      provider_class = Puppet::Type::Cs_rsc_location.provider(Puppet::Type::Cs_rsc_location.providers[0])
      Puppet::Type::Cs_rsc_location.expects(:defaultprovider).returns(provider_class)
      subject.new(:name => "mock_resource").should_not be_nil
    end

    [:cib, :name ].each do |param|
      it "should have a #{param} parameter" do
        subject.validparameter?(param).should be_true
      end

      it "should have documentation for its #{param} parameter" do
        subject.paramclass(param).doc.should be_instance_of(String)
      end
    end

    [:primitive,:node_score,:rules,:node_name].each do |property|
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
      pending("fix shadow invocation")
      @csresource_foo = Puppet::Type.type(:cs_resource).new(:name => 'foo', :ensure => :present)
      @shadow = Puppet::Type.type(:cs_shadow).new(:name => 'baz',:cib=>"baz")
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource @shadow, @csresource_foo
    end

    it "should autorequire the corresponding resources" do

      @resource = described_class.new(:name => 'dummy', :primitive => 'foo', :cib=>"baz")

      @catalog.add_resource @resource
      req = @resource.autorequire
      req.size.should == 2
      req.each do |e|
        #rewrite this f*cking should method of property type by the ancestor method
        class << e.target
          def should(*args)
            Object.instance_method(:should).bind(self).call(*args)
          end
        end
        e.target.should eql(@resource)
        [@csresource_foo,@shadow].should include(e.source)
      end
    end

  end
end
