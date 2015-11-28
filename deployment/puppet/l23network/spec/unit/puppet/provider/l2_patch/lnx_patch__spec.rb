require 'spec_helper'

describe Puppet::Type.type(:l2_patch).provider(:ovs) do
  # NOTE! for bridges ['br1', 'br2'] jack names will be ['p_39a440c1-0', 'p_39a440c1-1']


  let(:resource_br1) {
    Puppet::Type.type(:l2_bridge).new(
      :provider => 'lnx',
      :name     => 'br1',
      :bridge   => 'br1',
    )
  }
  let(:provider_br1) { resource_br1.provider }
  #let(:instance_br1_ovs) { provider_br1.class.instances }

  let(:resource_patch) {
    Puppet::Type.type(:l2_patch).new(
      :provider => 'lnx',
      :name     => 'patch__br1--br2',
      :bridges  => ['br1', 'br2'],
      :jacks    => ['p_39a440c1-0', 'p_39a440c1-1'],
      :mtu      => '9000'
    )
  }
  let(:provider_patch) { resource_patch.provider }
  #let(:instance_patch_ovs) { provider_patch.class.instances }

  describe "lnx-to-lnx patchcord" do

    let(:resource_br2) {
      Puppet::Type.type(:l2_bridge).new(
        :provider => 'lnx',
        :name     => 'br2',
        :bridge   => 'br2',
      )
    }
    let(:provider_br2) { resource_br2.provider }
    #let(:instance_br2_ovs) { provider_br2.class.instances }


    before(:each) do
      puppet_debug_override()
      provider_br1.class.stubs(:iproute)
      provider_br2.class.stubs(:iproute)
      provider_br1.class.stubs(:brctl).with(['addbr', 'br1']).returns(true)
      provider_br2.class.stubs(:brctl).with(['addbr', 'br2']).returns(true)
      provider_patch.class.stubs(:iproute).with([
        'link', 'add', 'dev', 'p_39a440c1-0', 'type', 'veth', 'peer', 'name', 'p_39a440c1-1'
      ]).returns(true)
      provider_patch.class.stubs(:get_bridge_list).returns({
        'br1' => {:br_type => :lnx},
        'br2' => {:br_type => :lnx},
      })
      provider_patch.class.stubs(:iproute).with(['link', 'set', 'dev', 'p_39a440c1-0', 'master', 'br1']).returns(true)
      provider_patch.class.stubs(:iproute).with(['link', 'set', 'dev', 'p_39a440c1-1', 'master', 'br2']).returns(true)
      provider_patch.class.stubs(:interface_up).with('p_39a440c1-0', true).returns(true)
      provider_patch.class.stubs(:interface_up).with('p_39a440c1-1', true).returns(true)
    end

    it "Just create two bridges and connect it by patchcord" do
      provider_br1.create
      provider_br2.create
      provider_patch.create
    end

  end

end
