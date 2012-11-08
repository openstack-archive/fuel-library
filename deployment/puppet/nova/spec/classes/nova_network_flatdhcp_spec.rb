require 'spec_helper'

describe 'nova::network::flatdhcp' do

  describe 'with only required parameters' do
    let :params do
      {
        :flat_interface => 'eth1',
        :fixed_range    => '10.0.0.0/32'
      }
    end

    it { should contain_nova_config('network_manager').with_value('nova.network.manager.FlatDHCPManager') }
    it { should_not contain_nova_config('public_interface') }
    it { should contain_nova_config('fixed_range').with_value('10.0.0.0/32') }
    it { should contain_nova_config('flat_interface').with_value('eth1') }
    it { should contain_nova_config('flat_interface').with_value('eth1') }
    it { should contain_nova_config('flat_network_bridge').with_value('br100') }
    it { should contain_nova_config('force_dhcp_release').with_value('true') }
    it { should contain_nova_config('flat_injected').with_value('false') }
    it { should contain_nova_config('dhcpbridge').with_value('/usr/bin/nova-dhcpbridge') }
    it { should contain_nova_config('dhcpbridge_flagfile').with_value('/etc/nova/nova.conf') }
  end

  describe 'when overriding class parameters' do

    let :params do
      {
        :flat_interface => 'eth1',
        :fixed_range    => '10.0.0.0/32',
        :public_interface    => 'eth0',
        :flat_network_bridge => 'br1001',
        :force_dhcp_release  => false,
        :flat_injected       => true,
        :dhcpbridge          => '/usr/bin/dhcpbridge',
        :dhcpbridge_flagfile => '/etc/nova/nova-dhcp.conf' 
      }
    end

    it { should contain_nova_config('public_interface').with_value('eth0') }
    it { should contain_nova_config('flat_network_bridge').with_value('br1001') }
    it { should contain_nova_config('force_dhcp_release').with_value('false') }
    it { should contain_nova_config('flat_injected').with_value('true') }
    it { should contain_nova_config('dhcpbridge').with_value('/usr/bin/dhcpbridge') }
    it { should contain_nova_config('dhcpbridge_flagfile').with_value('/etc/nova/nova-dhcp.conf') }

  end 

end
