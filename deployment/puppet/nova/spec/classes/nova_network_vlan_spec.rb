require 'spec_helper'

describe 'nova::network::vlan' do

  describe 'with only required parameters' do
    let :params do
      {
        :vlan_interface => 'eth1',
        :fixed_range    => '10.0.0.0/32'
      }
    end

    it { should contain_nova_config('network_manager').with_value('nova.network.manager.VlanManager') }
    it { should_not contain_nova_config('public_interface') }
    it { should contain_nova_config('fixed_range').with_value('10.0.0.0/32') }
    it { should contain_nova_config('vlan_start').with_value('300') }
    it { should contain_nova_config('vlan_interface').with_value('eth1') }

  end

  describe 'with parameters overridden' do

    let :params do
      {
        :vlan_interface   => 'eth1',
        :fixed_range      => '10.0.0.0/32',
        :public_interface => 'eth0',
        :vlan_start       => '100'
      }
    end

    it { should contain_nova_config('network_manager').with_value('nova.network.manager.VlanManager') }
    it { should contain_nova_config('public_interface').with_value('eth0') }
    it { should contain_nova_config('fixed_range').with_value('10.0.0.0/32') }
    it { should contain_nova_config('vlan_start').with_value('100') }
    it { should contain_nova_config('vlan_interface').with_value('eth1') }
  end
end
