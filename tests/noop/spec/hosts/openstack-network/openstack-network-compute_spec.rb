require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/openstack-network-compute.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    internal_address = Noop.node_hash['internal_address']
    use_neutron = Noop.hiera 'use_neutron'

    # Network
    if use_neutron
      it 'should declare openstack::network with neutron_server parameter set to false' do
        should contain_class('openstack::network').with(
          'neutron_server' => 'false',
        )
      end

      it 'should pass auth region to openstack::network' do
        should contain_class('openstack::network').with(
         'region' => 'RegionOne',
        )
      end

      it 'should configure auth region for neutron-agents' do
        should contain_class('openstack::network::neutron_agents').with(
         'auth_region' => 'RegionOne',
        )
      end
    else
      it 'should declare openstack::network with neutron_server parameter set to false' do
        should contain_class('openstack::network').with(
          'neutron_server' => 'false',
        )
      end
    end

    if use_neutron
      it 'should create /etc/libvirt/qemu.conf file that notifies libvirt service' do
        should contain_file('/etc/libvirt/qemu.conf').with(
          'ensure' => 'present',
          'source' => 'puppet:///modules/nova/libvirt_qemu.conf',
        ).that_notifies('Service[libvirt]')
      end
      it 'should configure linuxnet_interface_driver and linuxnet_ovs_integration_bridge' do
        should contain_nova_config('DEFAULT/linuxnet_interface_driver').with(
          'value' => 'nova.network.linux_net.LinuxOVSInterfaceDriver',
        )
        should contain_nova_config('DEFAULT/linuxnet_ovs_integration_bridge').with(
          'value' => 'br-int',
        )
      end
      it 'should configure net.bridge.bridge* keys that come before libvirt service' do
        should contain_augeas('sysctl-net.bridge.bridge-nf-call-arptables').with(
          'context' => '/files/etc/sysctl.conf',
          'changes' => "set net.bridge.bridge-nf-call-arptables '1'",
        ).that_comes_before('Service[libvirt]')
        should contain_augeas('sysctl-net.bridge.bridge-nf-call-iptables').with(
          'context' => '/files/etc/sysctl.conf',
          'changes' => "set net.bridge.bridge-nf-call-iptables '1'",
        ).that_comes_before('Service[libvirt]')
        should contain_augeas('sysctl-net.bridge.bridge-nf-call-ip6tables').with(
          'context' => '/files/etc/sysctl.conf',
          'changes' => "set net.bridge.bridge-nf-call-ip6tables '1'",
        ).that_comes_before('Service[libvirt]')
      end

      neutron_config =  Noop.hiera_structure 'quantum_settings'
      network_config =  Noop.hiera_structure 'network'

      if network_config && network_config.has_key?('neutron_dvr')
        dvr = network_config['neutron_dvr']
        it 'should configure neutron DVR' do
           should contain_class('openstack::network').with(
             'dvr' => dvr,
           )
        end
        if dvr
          it 'should set dvr mode for neutron l3 agent' do
             should contain_class('openstack::network::neutron_agents').with(
               'agent_mode' => 'dvr',
             )
          end
        end
      end

      if network_config && network_config.has_key?('neutron_l2_pop')
        l2_pop = network_config['neutron_l2_pop']
        it 'should configure neutron L2 population' do
           should contain_class('openstack::network').with(
             'l2_pop' => l2_pop,
           )
        end
      end

      if neutron_config && neutron_config.has_key?('L2') && neutron_config['L2'].has_key?('tunnel_id_ranges')
        tunnel_types = ['gre']
        it 'should configure tunnel_types for neutron' do
           should contain_class('openstack::network').with(
             'tunnel_types' => tunnel_types,
           )
           should contain_class('neutron::agents::ml2::ovs').with(
             'tunnel_types' => tunnel_types ? tunnel_types.join(",") : "",
           )
        end
      elsif neutron_config && neutron_config.has_key?('L2') && !neutron_config['L2'].has_key?('tunnel_id_ranges')
          it 'should declare openstack::network with tunnel_types set to []' do
            should contain_class('openstack::network').with(
              'tunnel_types' => [],
            )
          end
      end
    else
      it 'should configure multi_host, send_arp_for_ha, metadata_host in nova.conf for nova-network' do
        should contain_nova_config('DEFAULT/multi_host').with(
          'value' => 'True',
        )
        should contain_nova_config('DEFAULT/send_arp_for_ha').with(
          'value' => 'True',
        )
        should contain_nova_config('DEFAULT/metadata_host').with(
          'value' => internal_address,
        )
      end
      it 'should declare openstack::network with neutron disabled' do
        should contain_class('openstack::network').with(
          'neutron_server' => 'false',
        )
      end
    end
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

