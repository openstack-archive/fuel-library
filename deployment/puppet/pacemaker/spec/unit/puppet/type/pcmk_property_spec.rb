require 'spec_helper'

describe Puppet::Type.type(:pcmk_property) do
  subject do
    Puppet::Type.type(:pcmk_property)
  end

  it "should have a 'name' parameter" do
    expect(
        subject.new(
            :name => 'mock_resource',
            :value => 'mock_value'
        )[:name]
    ).to eq 'mock_resource'
  end

  describe 'basic structure' do
    it 'should be able to create an instance' do
      expect(
          subject.new(
              :name => 'mock_resource',
              :value => 'mock_value'
          )
      ).to_not be_nil
    end

    [:cib, :name ].each do |param|
      it "should have a #{param} parameter" do
        expect(subject.validparameter?(param)).to be_truthy
      end

      it "should have documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_a String
      end
    end

    it 'should have a value property' do
      expect(subject.validproperty?(:value)).to be_truthy
    end

    it 'should have documentation for its value property' do
      expect(subject.propertybyname(:value).doc).to be_a String
    end
  end

  describe 'when autorequiring resources' do
    before :each do
      @pcmk_shadow = Puppet::Type.type(:pcmk_shadow).new(
          :name => 'baz',
          :cib => 'baz'
      )
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource @pcmk_shadow
    end

    it 'should autorequire the corresponding resources' do
      @resource = described_class.new(
          :name => 'dummy',
          :value => 'foo',
          :cib => 'baz'
      )
      @catalog.add_resource @resource
      required_resources = @resource.autorequire
      expect(required_resources.size).to eq 1
      expect(required_resources.first.target).to eq @resource
      expect(required_resources.first.source).to eq @pcmk_shadow
    end
  end

end
