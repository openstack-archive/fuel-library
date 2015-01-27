require 'spec_helper'

describe Puppet::Type.type(:pcmk_property).provider(:ruby) do

  let(:resource) { Puppet::Type.type(:pcmk_property).new(
      :name => 'my_property',
      :value => 'my_value',
      :provider => :ruby,
  )}
  let(:provider) do
    provider = resource.provider
    if ENV['SPEC_PUPPET_DEBUG']
      class << provider
        def debug(str)
          puts str
        end
      end
    end
    provider
  end

  describe '#exists?' do
    it 'should determine if the property is defined' do
      provider.expects(:cluster_property_defined?).with('my_property')
      provider.exists?
    end
  end

  describe '#create' do
    it 'should create property with corresponding value' do
      provider.expects(:cluster_property_set).with('my_property', 'my_value')
      provider.create
    end
  end

  describe '#update' do
    it 'should update property with corresponding value' do
      provider.expects(:cluster_property_set).with('my_property', 'my_value')
      provider.create
    end
  end

  describe '#destroy' do
    it 'should destroy property with corresponding name' do
      provider.expects(:cluster_property_delete).with('my_property')
      provider.destroy
    end
  end

end

