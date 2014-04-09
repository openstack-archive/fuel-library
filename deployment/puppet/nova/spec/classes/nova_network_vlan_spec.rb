require 'spec_helper'

describe 'nova::network::vlan' do

  describe 'with only required parameters' do
    let :params do
      {
        :vlan_interface => 'eth1',
        :fixed_range    => '10.0.0.0/32'
      }
    end

    it { should contain_nova_config('DEFAULT/network_manager').with_value('nova.network.manager.VlanManager') }
    it { should_not contain_nova_config('DEFAULT/public_interface') }
    it { should contain_nova_config('DEFAULT/fixed_range').with_value('10.0.0.0/32') }
    it { should contain_nova_config('DEFAULT/vlan_start').with_value('300') }
    it { should contain_nova_config('DEFAULT/vlan_interface').with_value('eth1') }
    it { should contain_nova_config('DEFAULT/force_dhcp_release').with_value(true) }
    it { should contain_nova_config('DEFAULT/dhcpbridge').with_value('/usr/bin/nova-dhcpbridge') }
    it { should contain_nova_config('DEFAULT/dhcpbridge_flagfile').with_value('/etc/nova/nova.conf') }

  end

  describe 'with parameters overridden' do

    let :params do
      {
        :vlan_interface   => 'eth1',
        :fixed_range      => '10.0.0.0/32',
        :public_interface => 'eth0',
        :vlan_start       => '100',
        :force_dhcp_release  => false,
        :dhcpbridge          => '/usr/bin/dhcpbridge',
        :dhcpbridge_flagfile => '/etc/nova/nova-dhcp.conf'
      }
    end

    it { should contain_nova_config('DEFAULT/network_manager').with_value('nova.network.manager.VlanManager') }
    it { should contain_nova_config('DEFAULT/public_interface').with_value('eth0') }
    it { should contain_nova_config('DEFAULT/fixed_range').with_value('10.0.0.0/32') }
    it { should contain_nova_config('DEFAULT/vlan_start').with_value('100') }
    it { should contain_nova_config('DEFAULT/vlan_interface').with_value('eth1') }
    it { should contain_nova_config('DEFAULT/force_dhcp_release').with_value(false) }
    it { should contain_nova_config('DEFAULT/dhcpbridge').with_value('/usr/bin/dhcpbridge') }
    it { should contain_nova_config('DEFAULT/dhcpbridge_flagfile').with_value('/etc/nova/nova-dhcp.conf') }
  end
end
