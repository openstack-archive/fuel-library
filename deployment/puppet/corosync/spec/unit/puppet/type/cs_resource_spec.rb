require 'spec_helper'

describe Puppet::Type.type(:cs_resource) do
  subject do
    Puppet::Type.type(:cs_resource)
  end

  it "should have a 'name' parameter" do
    type = subject.new(:name => 'mock_resource')
    expect(type[:name]).to eq('mock_resource')
  end

  describe 'basic structure' do
    it 'should be able to create an instance' do
      expect(subject.new(:name => 'mock_resource')).to_not be_nil
    end

    [:name, :cib].each do |param|
      it "should have a #{param} parameter" do
        expect(subject.validparameter?(param)).to be_truthy
      end

      it "should have documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_instance_of(String)
      end
    end

    [:primitive_class, :primitive_type, :primitive_provider,
     :parameters, :operations, :complex_metadata, :complex_type].each do |property|
      it "should have a #{property} property" do
        expect(subject.validproperty?(property)).to be_truthy
      end

      it "should have documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_instance_of(String)
      end
    end
  end

  describe 'when validating attributes' do
    [:parameters, :operations, :metadata, :complex_metadata].each do |attribute|
      it "should validate that the #{attribute} attribute defaults to nil" do
        expect(subject.new(:name => 'mock_resource')[:parameters]).to be_nil
      end

      it "should validate that the #{attribute} attribute must be a hash" do
        expect {
          subject.new(
              :name => 'mock_resource',
              :parameters => 'fail'
          )
        }.to raise_error(Puppet::Error, /hash/)
      end
    end

    it 'should validate that the complex_type type attribute cannot be other values' do
      ['fail', 42].each do |value|
        expect {
          subject.new(
              :name => 'mock_resource',
              :complex_type => value
          )
        }.to raise_error(Puppet::Error, /(master|clone|\'\')/)
      end
    end
  end

  describe 'when autorequiring resources' do

    before :each do
      @shadow = Puppet::Type.type(:cs_shadow).new(:name => 'baz', :cib => 'baz')
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource @shadow
    end

    it 'should autorequire the corresponding resources' do

      @resource = described_class.new(:name => 'dummy', :cib => 'baz')

      @catalog.add_resource @resource
      req = @resource.autorequire
      expect(req.size).to eq(1)
      #rewrite this f*cking should method of property type by the ancestor method
      [req[0].target, req[0].source].each do |instance|
        class << instance
          def should(*args)
            Object.instance_method(:should).bind(self).call(*args)
          end
        end
      end
      expect(req[0].target).to eql(@resource)
      expect(req[0].source).to eql(@shadow)
    end

  end

  describe 'munging of input data' do
    [:parameters, :metadata, :complex_metadata].each do |hash|
      it "should convert hash keys and values to strings on #{hash}" do
        @type = subject.new({:name => 'myresource'})
        @type[hash] = {:a => 1, 'b' => true, 'c' => {:a => true, 'b' => :s, 4 => 'd'}}
        expected_data = {'a' => '1', 'b' => 'true', 'c' => {'a' => 'true', 'b' => 's', '4' => 'd'}}
        expect(@type[hash]).to eq expected_data
      end
    end

    context 'on operations' do

      it 'should change operations format if provided as hash' do
        data_from = {"start" => {"timeout" => "20", "interval" => "0"}, "monitor" => {"interval" => "10"}}
        data_to = [{"interval" => "10", "name" => "monitor"}, {"timeout" => "20", "name" => "start", "interval" => "0"}]
        type = subject.new(:name => 'mock_resource', :operations => data_from)
        expect(type[:operations]).to eq data_to
      end

      it 'should leave array of hashes untouched' do
        data_from = [{"interval" => "10", "name" => "monitor"}, {"timeout" => "20", "name" => "start", "interval" => "0"}]
        data_to = [{"interval" => "10", "name" => "monitor"}, {"timeout" => "20", "name" => "start", "interval" => "0"}]
        type = subject.new(:name => 'mock_resource', :operations => data_from)
        expect(type[:operations]).to eq data_to
      end

      it 'should add missing interval values' do
        data_from = [{"interval" => "10", "name" => "monitor"}, {"timeout" => "20", "name" => "start"}]
        data_to = [{"interval" => "10", "name" => "monitor"}, {"timeout" => "20", "name" => "start", "interval" => "0"}]
        type = subject.new(:name => 'mock_resource', :operations => data_from)
        expect(type[:operations]).to eq data_to
      end

      it 'should capitalize role value' do
        data_from = [{"interval" => "10", "name" => "monitor", "role" => "master"}]
        data_to = [{"interval" => "10", "name" => "monitor", "role" => "Master"}]
        type = subject.new(:name => 'mock_resource', :operations => data_from)
        expect(type[:operations]).to eq data_to
      end

      it 'should stringify operations structure' do
        data_from = {'interval' => 10, :name => 'monitor'}
        data_to = [{'interval' => '10', 'name' => 'monitor'}]
        type = subject.new(:name => 'mock_resource', :operations => data_from)
        expect(type[:operations]).to eq data_to
      end

    end

    describe 'special insync? conditions' do
      before :each do
        @type = subject.new (
                                {
                                    :name => 'my_resource',
                                    :complex_metadata => {
                                        'a' => 1,
                                        'target-role' => 'Stopped',
                                    },
                                    :metadata => {
                                        'a' => 2,
                                        'is-managed' => 'true',
                                    },
                                    :complex_type => 'master',
                                }
                            )
      end

      it 'should ignore status metadata from complex_metadata hash comparison' do
        complex_metadata = @type.property(:complex_metadata)
        expect(complex_metadata.insync?({"a" => "1", "target-role" => "Started"})).to be_truthy
      end

      it 'should ignore status metadata from metadata hash comparison' do
        metadata = @type.property(:metadata)
        expect(metadata.insync?({"a" => "2", "is-managed" => "false"})).to be_truthy
      end

      it 'should compare non-status complex_metadata' do
        complex_metadata = @type.property(:complex_metadata)
        expect(complex_metadata.insync?({'a' => 2})).to be_falsey
      end

      it 'should compare non-status metadata' do
        metadata = @type.property(:metadata)
        expect(metadata.insync?({'a' => 1})).to be_falsey
      end
    end

  end

end
