require 'spec_helper'

describe Puppet::Type.type(:cs_commit) do
  subject do
    Puppet::Type.type(:cs_commit)
  end

  it "should have a 'name' parameter" do
    expect(subject.new(:name => 'mock_resource')[:name]).to eq 'mock_resource'
  end

  describe 'basic structure' do
    it 'should be able to create an instance' do
      expect(subject.new(:name => 'mock_resource')).to_not be_nil
    end

    [:name].each do |param|
      it "should have a #{param} parameter" do
        expect(subject.validparameter?(param)).to be_truthy
      end

      it "should have documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_a String
      end
    end
    [:cib].each do |property|
      it "should have a #{property} property" do
        expect(subject.validproperty?(property)).to be_truthy
      end

      it "should have documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_a String
      end
    end

  end

  describe 'when autorequiring resources' do

    before :each do
      @csresource_foo = Puppet::Type.type(:cs_resource).new(
          :name => 'p_foo',
          :cib => 'baz',
          :ensure => :present
      )
      @cslocation_foo = Puppet::Type.type(:cs_location).new(
          :name => 'l_foo',
          :primitive => 'my_primitive',
          :node_name => 'my_node',
          :node_score => '100',
          :cib => 'baz',
          :ensure => :present
      )
      @csorder_foo = Puppet::Type.type(:cs_order).new(
          :name => 'o_foo',
          :cib => 'baz',
          :first => 'a',
          :second => 'b',
          :ensure => :present
      )
      @cscolocation_foo = Puppet::Type.type(:cs_colocation).new(
          :name => 'c_foo',
          :cib => 'baz',
          :ensure => :present,
          :primitives => %w(foo bar)
      )
      @csproperty_foo = Puppet::Type.type(:cs_property).new(
          :name => 'pr_foo',
          :cib => 'baz',
          :value => 'bar',
          :ensure => :present
      )
      @csshadow = Puppet::Type.type(:cs_shadow).new(
          :name => 'baz',
          :cib => 'baz'
      )
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource @cslocation_foo,
                            @csresource_foo,
                            @csproperty_foo,
                            @csorder_foo,
                            @cscolocation_foo,
                            @csshadow
    end

    it 'should autorequire the corresponding resources' do

      @resource = @csshadow.generate[0]
      @catalog.add_resource @resource
      cs_resources = [
          @cslocation_foo,
          @csresource_foo,
          @csproperty_foo,
          @csorder_foo,
          @cscolocation_foo,
          @csshadow,
      ]
      required_resources = @resource.autorequire
      required_resources.each do |e|
        expect(e.target).to eq @resource
        expect(cs_resources).to include e.source
      end
      expect(required_resources.size).to eq 6
    end

  end
end
