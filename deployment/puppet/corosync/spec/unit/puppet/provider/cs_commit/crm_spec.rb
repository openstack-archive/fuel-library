require 'spec_helper'

describe Puppet::Type.type(:cs_commit).provider(:crm) do

  let(:resource) { Puppet::Type.type(:cs_commit).new(:name => 'mycib', :provider=> :crm ) }
  let(:provider) { resource.provider }

  describe "#commit" do
    it "should commit corresponding cib" do
      provider.class.stubs(:block_until_ready).returns(true)
      provider.expects(:crm).with('cib','commit','mycib')
      provider.sync('mycib')
    end
  end
end

