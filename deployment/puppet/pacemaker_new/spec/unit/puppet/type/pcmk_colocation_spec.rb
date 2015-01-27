require 'spec_helper'

describe Puppet::Type.type(:pcmk_colocation) do
  subject do
    Puppet::Type.type(:pcmk_colocation)
  end

  it "should have a 'name' parameter" do
    expect(subject.new(:name => 'mock_resource', :primitives => %w(foo bar))[:name]).to eq 'mock_resource'
  end

  describe 'basic structure' do
    it 'should be able to create an instance' do
      expect(subject.new(:name => 'mock_resource', :primitives => %w(foo bar))).to_not be_nil
    end

    [:cib, :name].each do |param|
      it "should have a #{param} parameter" do
        expect(subject.validparameter?(param)).to be_truthy
      end

      it "should have documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_a String
      end
    end

    [:primitives, :score].each do |property|
      it "should have a #{property} property" do
        expect(subject.validproperty?(property)).to be_truthy
      end
      it "should have documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_a String
      end

    end

    it 'should validate the score values' do
      ['fadsfasdf', nil].each do |value|
        expect { subject.new(
            :name => 'mock_colocation',
            :primitives => %w(foo bar),
            :score => value
        ) }.to raise_error
      end
    end

    it 'should change inf to INFINITY in score' do
      expect(subject.new(
                 :name => 'mock_colocation',
                 :primitives => %w(foo bar),
                 :score => 'inf'
             )[:score]).to eq 'INFINITY'
    end

    it 'should validate that the primitives must be a two_value array' do
      ['1', %w(1), %w(1 2 3)].each do |value|
        expect { subject.new(
            :name => 'mock_colocation',
            :primitives => value
        ) }.to raise_error
      end
    end

    describe 'when autorequiring resources' do
      before :each do
        @pcmk_resource_1 = Puppet::Type.type(:pcmk_resource).new(:name => 'foo', :ensure => :present)
        @pcmk_resource_2 = Puppet::Type.type(:pcmk_resource).new(:name => 'bar', :ensure => :present)
        @pcmk_shadow = Puppet::Type.type(:pcmk_shadow).new(:name => 'baz', :cib => 'baz')
        @catalog = Puppet::Resource::Catalog.new
        @catalog.add_resource @pcmk_shadow, @pcmk_resource_1, @pcmk_resource_2
      end

      it 'should autorequire the corresponding resources' do
        @resource = described_class.new(:name => 'dummy', :primitives => %w(foo bar), :cib => 'baz', :score => 'inf')
        @catalog.add_resource @resource
        required_resources = @resource.autorequire
        expect(required_resources.size).to eq 3
        required_resources.each do |e|
          expect(e.target).to eq @resource
          expect([@pcmk_resource_1, @pcmk_resource_2, @pcmk_shadow]).to include e.source
        end
      end
    end

  end

end
