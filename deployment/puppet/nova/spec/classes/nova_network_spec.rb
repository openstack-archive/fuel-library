require 'spec_helper'

describe 'nova::network' do

  let :pre_condition do
    'include nova'
  end

  let :default_params do
    {
      :private_interface => 'eth1',
      :fixed_range       => '10.0.0.0/32',
    }
  end

  let :params do
    default_params
  end

  describe 'on debian platforms' do

    let :facts do
      { :osfamily => 'Debian' }
    end

    it { should contain_sysctl__value('net.ipv4.ip_forward').with_value('1') }

    describe 'when installing service' do

      it { should contain_package('nova-network').with(
        'name'   => 'nova-network',
        'ensure' => 'present',
        'notify' => 'Service[nova-network]'
      ) }

      describe 'with enabled as true' do
        let :params do
          default_params.merge(:enabled => true)
        end
        it { should contain_service('nova-network').with(
          'name'      => 'nova-network',
          'ensure'    => 'running',
          'hasstatus' => true,
          'enable'    => true
        )}
      end
      describe 'when enabled is set to false' do
        it { should contain_service('nova-network').with(
          'name'      => 'nova-network',
          'ensure'    => 'stopped',
          'hasstatus' => true,
          'enable'    => false
        )}
      end
    end
    describe 'when not installing service' do

      let :params do
        default_params.merge(:install_service => false)
      end

      it { should_not contain_package('nova-network') }
      it { should_not contain_service('nova-network') }

    end

    describe 'when not creating networks' do
      let :params do
        default_params.merge(:create_networks => false)
      end
      it { should_not contain_nova__manage__network('nova-vm-net') }
      it { should_not contain_nova__manage__floating('nova-vm-floating') }
    end

    describe 'when creating networks' do
      it { should contain_nova__manage__network('nova-vm-net').with(
        :network      => '10.0.0.0/32',
        :num_networks => '1'
      ) }
      it { should_not contain__nova__manage__floating('nova-vm-floating') }
      describe 'when number of networks is set' do
        let :params do
          default_params.merge(:num_networks => '2')
        end
        it { should contain_nova__manage__network('nova-vm-net').with(
          :num_networks => '2'
        ) }
      end
      describe 'when floating range is set' do
        let :params do
          default_params.merge(:floating_range => '10.0.0.0/30')
        end
        it { should contain_nova_config('DEFAULT/floating_range').with_value('10.0.0.0/30') }
        it { should contain_nova__manage__floating('nova-vm-floating').with_network('10.0.0.0/30') }
      end
    end
    describe 'when configuring networks' do
      describe 'when configuring flatdhcpmanager' do
        let :params do
          default_params.merge(:network_manager => 'nova.network.manager.FlatDHCPManager')
        end
        it { should contain_class('nova::network::flatdhcp').with(
          :fixed_range          => '10.0.0.0/32',
          :public_interface     => nil,
          :flat_interface       => 'eth1',
          :flat_network_bridge  => 'br100',
          :force_dhcp_release   => true,
          :flat_injected        => false,
          :dhcp_domain          => 'novalocal',
          :dhcpbridge           => '/usr/bin/nova-dhcpbridge',
          :dhcpbridge_flagfile  => '/etc/nova/nova.conf'
        ) }
        describe 'when overriding parameters' do
          let :params do
            default_params.merge(
              {
                :network_manager  => 'nova.network.manager.FlatDHCPManager',
                :public_interface => 'eth0',
                :config_overrides =>
                  {
                    'flat_network_bridge' => 'br400',
                    'force_dhcp_release'  => false,
                    'flat_injected'       => true,
                    'dhcp_domain'         => 'not-novalocal',
                    'dhcpbridge'          => '/tmp/bridge',
                    'dhcpbridge_flagfile' => '/tmp/file',
                  }
              }
            )
          end
          it { should contain_class('nova::network::flatdhcp').with(
            :fixed_range          => '10.0.0.0/32',
            :public_interface     => 'eth0',
            :flat_interface       => 'eth1',
            :flat_network_bridge  => 'br400',
            #:force_dhcp_release   => false,
            :flat_injected        => true,
            :dhcp_domain          => 'not-novalocal',
            :dhcpbridge           => '/tmp/bridge',
            :dhcpbridge_flagfile  => '/tmp/file'
          ) }

        end
      end
      describe 'when configuring flatmanager' do
        let :params do
          default_params.merge(:network_manager => 'nova.network.manager.FlatManager')
        end
        it { should contain_class('nova::network::flat').with(
          :fixed_range         => '10.0.0.0/32',
          :public_interface    => nil,
          :flat_interface      => 'eth1',
          :flat_network_bridge => 'br100'
        ) }
        describe 'when overriding flat network params' do
          let :params do
            default_params.merge(
              {
                :network_manager  => 'nova.network.manager.FlatManager',
                :public_interface => 'eth0',
                :config_overrides => {'flat_network_bridge' => 'br400' }
              }
            )
          end
          it { should contain_class('nova::network::flat').with(
            :public_interface    => 'eth0',
            :flat_network_bridge => 'br400'
          ) }
          end
      end
      describe 'when configuring vlan' do
        let :params do
          default_params.merge(:network_manager => 'nova.network.manager.VlanManager')
        end
        it { should contain_class('nova::network::vlan').with(
          :fixed_range         => '10.0.0.0/32',
          :public_interface    => nil,
          :vlan_interface      => 'eth1',
          :force_dhcp_release  => true,
          :dhcp_domain         => 'novalocal',
          :dhcpbridge          => '/usr/bin/nova-dhcpbridge',
          :dhcpbridge_flagfile => '/etc/nova/nova.conf'
        ) }
        describe 'when overriding parameters' do
          let :params do
            default_params.merge(
              {
              }
            )
          end
        end
      end
    end
    describe 'with package version' do
      let :params do
        default_params.merge(:ensure_package => '2012.1-2')
      end
      it { should contain_package('nova-network').with(
        'ensure' => '2012.1-2'
      )}
    end
  end
  describe 'on rhel' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it { should contain_service('nova-network').with(
      'name'      => 'openstack-nova-network',
      'ensure'    => 'stopped',
      'hasstatus' => true,
      'enable'    => false
    )}
    it { should contain_package('nova-network').with_name('openstack-nova-network') }
  end
end
