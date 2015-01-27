require 'spec_helper'

describe Puppet::Type.type(:pcmk_shadow) do
  subject do
    Puppet::Type.type(:pcmk_shadow)
  end

  it "should have a 'name' parameter" do
    expect(
    subject.new(
        :name => 'mock_resource'
    )[:name]
    ).to eq 'mock_resource'
  end

  describe 'basic structure' do
    it 'should be able to create an instance' do
      expect(
        subject.new(
            :name => 'mock_resource'
        )
      ).to_not be_nil
    end

    [:name, :isempty].each do |param|
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
    before do
      @catalog = Puppet::Resource::Catalog.new
      @resource = described_class.new(
          :name => 'dummy',
          :cib => 'baz'
      )
      @catalog.add_resource @resource
    end

    it 'should generate the pcmk_commit resource with correct name' do
      generated = @resource.generate
      expect(generated.first.name).to eq @resource[:name]
      expect(generated.first).to be_a Puppet::Type::Pcmk_commit
    end
  end

end
