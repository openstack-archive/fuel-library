require 'spec_helper'

describe Puppet::Type.type(:pcmk_shadow).provider(:ruby) do

  let(:resource) { Puppet::Type.type(:pcmk_shadow).new(
      :name => 'my_shadow',
      :provider => :ruby,
      :cib => 'my_shadow'
  ) }
  let(:provider) { resource.provider }

  describe '#create' do
    before(:each) do
      provider.stubs(:wait_for_online).returns(true)
      provider.stubs(:cluster_debug_report).returns(true)
    end

    it 'should create a non-empty shadow' do
      provider.expects(:crm_shadow).with( '--force', '--delete', 'my_shadow')
      provider.expects(:crm_shadow).with( '--force', '--create', 'my_shadow')
      provider.sync('my_shadow')
    end

    it 'should create an empty shadow' do
      resource[:isempty] = true
      provider.expects(:crm_shadow).with( '--force', '--delete', 'my_shadow')
      provider.expects(:crm_shadow).with( '--force', '--create-empty', 'my_shadow')
      provider.sync('my_shadow')
    end
  end

end

