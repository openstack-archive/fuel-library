require 'spec_helper'

describe Puppet::Type.type(:cs_property).provider(:paceamker) do

  let(:resource) { Puppet::Type.type(:cs_property).new(
      :name => 'my_property',
      :value => 'my_value',
      :provider => :pacemaker
  )}
  let(:provider) { resource.provider }

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

