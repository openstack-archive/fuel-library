require 'spec_helper'

describe Puppet::Type.type(:cs_shadow).provider(:crm) do

  let(:resource) { Puppet::Type.type(:cs_shadow).new(:name => 'myshadow',  :provider=> :crm, :cib => 'myshadow' ) }
  let(:provider) { resource.provider }

  before :each do
    provider.class.stubs(:block_until_ready).returns(true)
  end

  describe "#create" do
    it "should create  non-empty shadow" do
      provider.expects(:crm).with('cib','delete','myshadow')
      provider.expects(:crm).with('cib','new','myshadow')
      provider.sync('myshadow')
    end
    it "should create  empty shadow" do
      resource[:isempty] = :true
      provider.expects(:crm).with('cib','delete','myshadow')
      provider.expects(:crm).with('cib','new','myshadow','empty')
      provider.sync('myshadow')
    end
  end

end

