require 'spec_helper'

type_class = Puppet::Type.type(:l2_port)
provider_class = type_class.provider(:lnx)

describe provider_class do

  describe "just ethN card" do

    let(:resource) do
      type_class.new(
          :ensure   => 'present',
          :bridge   => 'br1',
          :provider => :lnx,
          :name     => 'eth1',
      )
    end
    let(:provider) { resource.provider }

    before(:each) do
      puppet_debug_override()
    end

    it 'should exists' do
      expect(provider).not_to be_nil
    end

    it "Test for existing interface" do
      # this test emulates. that eth1 already initialized by 'ifup' command
      # create never call for HW interfaces, but it's not matter for this test
      provider.class.stubs(:iproute).returns(true)
      File.stubs(:directory?).with('/var/run/network').returns(true)
      File.stubs(:file?).with('/var/run/network/ifstate').returns(true)
      File.stubs(:file?).with('/var/run/network/ifstate.eth1').returns(true)
      File.stubs(:new).with('/var/run/network/ifstate', 'r').returns(StringIO.new("eth0=eth0\neth1=eth1\neth2=eth2\n"))
      provider.create
    end

  end

  describe "802.1q vlan subinterface" do

    let(:resource) do
      type_class.new(
          :ensure   => 'present',
          :bridge   => 'br1',
          :provider => :lnx,
          :use_ovs  => false,
          :name     => 'eth1.101',
          :vlan_dev => 'eth1',
          :vlan_id  => 101,

      )
    end
    let(:provider) { resource.provider }

    before(:each) do
      puppet_debug_override()
    end

    it 'should exists' do
      expect(provider).not_to be_nil
    end

    it "Test for newly-creatind interface" do
      # this test emulates. that eth1.101 not existed, and should be created
      file_f = StringIO.new
      file_a = StringIO.new
      File.stubs(:directory?).with('/var/run/network').returns(true)
      File.stubs(:file?).with('/var/run/network/ifstate').returns(false)
      File.stubs(:file?).with('/var/run/network/ifstate.eth1.101').returns(false)
      File.stubs(:new).with("/var/run/network/ifstate.eth1.101", mode="w").returns(file_f)
      File.stubs(:new).with("/var/run/network/ifstate", mode="w").returns(file_a)
      provider.class.stubs(:iproute).with(['link', 'add', 'link', 'eth1', 'name', 'eth1.101', 'type', 'vlan', 'id', 101]).returns(true)
      provider.create
      expect(file_f.string).to match(/eth1\.101/)
      expect(file_a.string).to match(/eth1\.101=eth1\.101/)
    end

  end
end
