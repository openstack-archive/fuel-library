require 'spec_helper'

describe Puppet::Type.type(:cs_primitive) do
  subject do
    Puppet::Type.type(:cs_primitive)
  end

  it "should have a 'name' parameter" do
    expect(subject.new(:name => "mock_primitive")[:name]).to eq("mock_primitive")
  end

  describe "basic structure" do
    it "should be able to create an instance" do
      provider_class = Puppet::Type::Cs_primitive.provider(Puppet::Type::Cs_primitive.providers[0])
      Puppet::Type::Cs_primitive.expects(:defaultprovider).returns(provider_class)

      expect(subject.new(:name => "mock_primitive")).to_not be_nil
    end

    [:name, :primitive_class, :primitive_type, :provided_by, :cib].each do |param|
      it "should have a #{param} parameter" do
        expect(subject.validparameter?(param)).to be_truthy
      end

      it "should have documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_instance_of(String)
      end
    end

    [:parameters, :operations, :metadata, :ms_metadata, :promotable].each do |property|
      it "should have a #{property} property" do
        expect(subject.validproperty?(property)).to be_truthy
      end

      it "should have documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_instance_of(String)
      end
    end
  end

  describe "when validating attributes" do
    [:parameters, :operations, :metadata, :ms_metadata].each do |attribute|
      it "should validate that the #{attribute} attribute defaults to a hash" do
        expect(subject.new(:name => "mock_primitive")[:parameters]).to eq({})
      end

      it "should validate that the #{attribute} attribute must be a hash" do
        expect { subject.new(
          :name       => "mock_primitive",
          :parameters => "fail"
        ) }.to raise_error Puppet::Error, /hash/
      end
    end

    it "should validate that the promotable attribute can be true/false" do
      [true, false].each do |value|
        expect(subject.new(
          :name       => "mock_primitive",
          :promotable => value
        )[:promotable]).to eq(value.to_s.to_sym)
      end
    end

    it "should validate that the promotable attribute cannot be other values" do
      ["fail", 42].each do |value|
        expect { subject.new(
          :name       => "mock_primitive",
          :promotable => value
        ) }.to raise_error Puppet::Error, /(true|false)/
      end
    end
  end
end
