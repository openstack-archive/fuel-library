require 'spec_helper'

describe Puppet::Type.type(:pcmk_commit) do
  subject do
    Puppet::Type.type(:pcmk_commit)
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
      @pcmk_resource = Puppet::Type.type(:pcmk_resource).new(
          :name => 'p_foo',
          :cib => 'baz',
          :ensure => :present
      )
      @pcmk_location = Puppet::Type.type(:pcmk_location).new(
          :name => 'l_foo',
          :primitive => 'my_primitive',
          :node_name => 'my_node',
          :node_score => '100',
          :cib => 'baz',
          :ensure => :present
      )
      @pcmk_order = Puppet::Type.type(:pcmk_order).new(
          :name => 'o_foo',
          :cib => 'baz',
          :first => 'a',
          :second => 'b',
          :ensure => :present
      )
      @pcmk_colocation = Puppet::Type.type(:pcmk_colocation).new(
          :name => 'c_foo',
          :cib => 'baz',
          :ensure => :present,
          :primitives => %w(foo bar)
      )
      @pcmk_property = Puppet::Type.type(:pcmk_property).new(
          :name => 'pr_foo',
          :cib => 'baz',
          :value => 'bar',
          :ensure => :present
      )
      @pcmk_shadow = Puppet::Type.type(:pcmk_shadow).new(
          :name => 'baz',
          :cib => 'baz'
      )
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource @pcmk_location,
                            @pcmk_resource,
                            @pcmk_property,
                            @pcmk_order,
                            @pcmk_colocation,
                            @pcmk_shadow
    end

    it 'should autorequire the corresponding resources' do
      @resource = @pcmk_shadow.generate[0]
      @catalog.add_resource @resource
      cs_resources = [
          @pcmk_location,
          @pcmk_resource,
          @pcmk_property,
          @pcmk_order,
          @pcmk_colocation,
          @pcmk_shadow,
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
