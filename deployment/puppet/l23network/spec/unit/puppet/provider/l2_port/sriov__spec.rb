require 'spec_helper'

describe Puppet::Type.type(:l2_port).provider(:sriov) do

  let(:resource_port) {
    Puppet::Type.type(:l2_port).new(
      :provider => 'sriov',
      :name     => 'eth0',
      :vendor_specific => {
          :sriov_numvfs => 63,
          :physnet => 'physnet2'
      },
    )
  }
  let(:provider_port) { resource_port.provider }

  describe "sriov port" do

    before(:each) do
      puppet_debug_override()
    end

    it "create" do
      File.stubs(:exists?).with('/sys/class/net/eth0/device/sriov_numvfs').returns(true)
      File.stubs(:open).with('/sys/class/net/eth0/device/sriov_numvfs', 'a').returns(true)
      File.stubs(:read).with('/sys/class/net/eth0/device/sriov_numvfs').returns(63)
      provider_port.class.stubs(:interface_up).with('eth0').returns(true)
      provider_port.create
      provider_port.flush
    end

  end

end
