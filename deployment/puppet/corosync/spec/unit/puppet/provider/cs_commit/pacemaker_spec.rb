require 'spec_helper'

describe Puppet::Type.type(:cs_commit).provider(:pacemaker) do

  let(:resource) { Puppet::Type.type(:cs_commit).new(:name => 'my_cib', :provider => :pacemaker ) }
  let(:provider) { resource.provider }

  describe '#commit' do
    it 'should commit corresponding cib' do
      provider.stubs(:wait_for_online).returns(true)
      provider.expects(:crm_shadow).with('--force', '--commit', 'my_cib').returns(true)
      provider.sync 'my_cib'
    end
  end

end

