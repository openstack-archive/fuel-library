require 'spec_helper'

describe Puppet::Type.type(:l3_ifconfig).provider(:lnx) do

  let(:resource) {
    Puppet::Type.type(:l3_ifconfig).new(
      :name      => 'eth1',
      :interface => 'eth1',
      :ensure    => :present,
      :ipaddr    => 'none',
      :gateway   => :absent,
      :provider  => :lnx
    )
  }

  let(:provider) { resource.provider }

  describe "l3_ifconfig " do
    before(:each) do
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end
    end

    it "no existing IPs on the given NIC" do
      provider.class.stubs(:get_if_defroutes_mappings).with().returns({})
      provider.class.stubs(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>[]}})
      provider.class.instances
      provider.create
      provider.class.stubs(:addr_flush).with('eth1', true)
      provider.flush
    end

    it "remove all existing IPs from the given NIC" do
      provider.class.stubs(:get_if_defroutes_mappings).with().returns({})
      provider.class.stubs(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>['1.1.1.1/24', '2.2.2.2/25']}})
      provider.class.instances
      provider.create
      provider.class.stubs(:addr_flush).with('eth1', true)
      provider.flush
    end
  end
end