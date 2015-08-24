require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/openstack-network-compute.pp'

describe manifest do

  shared_examples 'catalog' do

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:metadata_host) do
      prepare
      Noop.puppet_function 'get_network_role_property', 'mgmt/vip', 'ipaddr'
    end

    let(:neutron_dvr) do
      Noop.hiera_structure 'neutron_advanced_configuration/neutron_dvr'
    end

    let(:neutron_l2_pop) do
      Noop.hiera_structure 'neutron_advanced_configuration/neutron_l2_pop'
    end

    let(:segmentation_type) do
      Noop.hiera_structure 'neutron_config/L2/segmentation_type'
    end

    let(:use_gre_for_tun) do
      Noop.hiera_structure 'neutron_config/L2/use_gre_for_tun'
    end

    let(:tunnel_id_ranges) do
      Noop.hiera_structure 'neutron_config/L2/tunnel_id_ranges'
    end

    let(:tunnel_types) do
      if use_gre_for_tun
        ['gre']
      else
        ['vxlan']
      end
    end

    let(:tenant_network_types) do
      if use_gre_for_tun
        %w(flat vlan gre)
      else
        %w(flat vlan vxlan)
      end
    end

    ############################################################################

    it 'should declare openstack::network with use_stderr disabled' do
      should contain_class('openstack::network').with(
                 'use_stderr' => 'false'
             )
    end

    enable = Noop.hiera('use_neutron')
    context 'with Neutron', :if => enable do

      it 'should declare openstack::network with neutron_server parameter set to false' do
        should contain_class('openstack::network').with(
                   'neutron_server' => 'false'
               )
      end

      it 'should pass auth region to openstack::network' do
        should contain_class('openstack::network').with(
                   'region' => 'RegionOne'
               )
      end

      it 'should configure auth region for neutron-agents' do
        should contain_class('openstack::network::neutron_agents').with(
                   'auth_region' => 'RegionOne'
               )
      end

      it 'should wait for integration bridge' do
        should contain_exec('wait-for-int-br').with(
                   'command' => 'ovs-vsctl br-exists br-int'
               )
      end

      it {
        should contain_class('openstack::network').that_comes_before('Exec[wait-for-int-br]')
      }

      it {
        should contain_exec('wait-for-int-br').that_comes_before('Service[nova-compute]')
      }

      it 'should remove default libvirt network' do
        should contain_exec('destroy_libvirt_default_network').with(
                   'command' => 'virsh net-destroy default',
                   'onlyif' => 'virsh net-info default | grep -qE "Active:.* yes"',
                   'path' => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
                   'tries' => 3,
                   'require' => 'Service[libvirt]'
               )

        should contain_exec('undefine_libvirt_default_network').with(
                   'command' => 'virsh net-undefine default',
                   'onlyif' => 'virsh net-info default 2>&1 > /dev/null',
                   'path' => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
                   'tries' => 3,
                   'require' => 'Exec[destroy_libvirt_default_network]'
               )

        should contain_service('libvirt').that_notifies('Exec[destroy_libvirt_default_network]')
      end

      it 'should configure libvirt for qemu' do
        should contain_file_line('clear_emulator_capabilities').with(
                   'path' => '/etc/libvirt/qemu.conf',
                   'line' => 'clear_emulator_capabilities = 0'
               )

        should contain_file_line('no_qemu_selinux').with(
                   'path' => '/etc/libvirt/qemu.conf',
                   'line' => 'security_driver = "none"'
               )
      end

      it 'should configure linuxnet_interface_driver and linuxnet_ovs_integration_bridge' do
        should contain_nova_config('DEFAULT/linuxnet_interface_driver').with(
                   'value' => 'nova.network.linux_net.LinuxOVSInterfaceDriver'
               )

        should contain_nova_config('DEFAULT/linuxnet_ovs_integration_bridge').with(
                   'value' => 'br-int'
               )
      end

      it 'should configure net.bridge.bridge* keys that come before libvirt service' do
        should contain_augeas('sysctl-net.bridge.bridge-nf-call-arptables').with(
                   'context' => '/files/etc/sysctl.conf',
                   'changes' => "set net.bridge.bridge-nf-call-arptables '1'"
               ).that_comes_before('Service[libvirt]')
        should contain_augeas('sysctl-net.bridge.bridge-nf-call-iptables').with(
                   'context' => '/files/etc/sysctl.conf',
                   'changes' => "set net.bridge.bridge-nf-call-iptables '1'"
               ).that_comes_before('Service[libvirt]')
        should contain_augeas('sysctl-net.bridge.bridge-nf-call-ip6tables').with(
                   'context' => '/files/etc/sysctl.conf',
                   'changes' => "set net.bridge.bridge-nf-call-ip6tables '1'"
               ).that_comes_before('Service[libvirt]')
      end

      enable = Noop.hiera_structure('neutron_advanced_configuration/neutron_dvr')
      context 'with neutron_dvr', :if => enable do

        it 'should configure neutron DVR' do
          should contain_class('openstack::network').with(
                     'dvr' => neutron_dvr
                 )
        end

        it 'should set dvr mode for neutron l3 agent' do
          should contain_class('openstack::network::neutron_agents').with(
                     'agent_mode' => 'dvr'
                 )
        end
      end

      enable = Noop.hiera_structure('neutron_advanced_configuration/neutron_l2_pop')
      it 'should configure neutron L2 population', :if => enable do
        should contain_class('openstack::network').with(
                   'l2_population' => neutron_l2_pop
               )
      end

      enable = Noop.hiera_structure('neutron_config/L2/segmentation_type') == 'gre'
      context 'segmentation_type = GRE', :if => enable  do
        it 'should configure tunnel_types for neutron and set net_mtu' do
          should contain_class('openstack::network').with(
                     'tunnel_types' => tunnel_types,
                     'tunnel_id_ranges' => tunnel_id_ranges,
                     'vni_ranges' => tunnel_id_ranges,
                     'tenant_network_types' => tenant_network_types,
                     'net_mtu' => 1500,
                     'network_device_mtu' => 1450
                 )
          should contain_class('neutron::plugins::ml2').with(
                     'tunnel_id_ranges' => tunnel_id_ranges,
                     'vni_ranges' => tunnel_id_ranges,
                     'tenant_network_types' => tenant_network_types
                 )
          should contain_class('neutron::agents::ml2::ovs').with(
                     'tunnel_types' => tunnel_types ? tunnel_types.join(",") : ""
                 )
        end
      end
    end

    enable = Noop.hiera('use_neutron')
    context 'with Nova-Network', :unless => enable do

      it 'should declare openstack::network with neutron_server parameter set to false' do
        should contain_class('openstack::network').with(
                   'neutron_server' => 'false'
               )
      end

      it 'should configure multi_host, send_arp_for_ha, metadata_host in nova.conf for nova-network' do
        should contain_nova_config('DEFAULT/multi_host').with(
                   'value' => 'True'
               )
        should contain_nova_config('DEFAULT/send_arp_for_ha').with(
                   'value' => 'True'
               )
        should contain_nova_config('DEFAULT/metadata_host').with(
                   'value' => metadata_host
               )
      end

      it 'should declare openstack::network with neutron disabled' do
        should contain_class('openstack::network').with(
                   'neutron_server' => 'false'
               )
      end

      enable = Noop.hiera_structure('neutron_config/L2/segmentation_type') == 'vlan'
      context 'segmentation_type = VLAN', :if => enable do
        it 'should declare openstack::network with tunnel_types set to [] and set net_mtu' do
          should contain_class('openstack::network').with(
                     'tunnel_types' => [],
                     'net_mtu' => 1500,
                     'network_device_mtu' => 1500
                 )
        end
      end

    end

  end

  test_ubuntu_and_centos manifest
end

