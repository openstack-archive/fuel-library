require 'spec_helper'

describe Puppet::Type.type(:cs_rsc_default).provider(:paceamker) do

  let(:resource) { Puppet::Type.type(:cs_rsc_default).new(
      :name => 'my_default',
      :value => 'my_value',
      :provider => :pacemaker
  )}
  let(:provider) { resource.provider }

  describe '#exists?' do
    it 'should determine if the rsc_default is defined' do
      provider.expects(:resource_default_defined?).with('my_default')
      provider.exists?
    end
  end

  describe '#create' do
    it 'should create resource default with corresponding value' do
      provider.expects(:resource_default_set).with('my_default', 'my_value')
      provider.create
    end
  end

  describe '#update' do
    it 'should update resource default with corresponding value' do
      provider.expects(:resource_default_set).with('my_default', 'my_value')
      provider.create
    end
  end

  describe '#destroy' do
    it 'should destroy resource default with corresponding name' do
      provider.expects(:resource_default_delete).with('my_default')
      provider.destroy
    end
  end

end

