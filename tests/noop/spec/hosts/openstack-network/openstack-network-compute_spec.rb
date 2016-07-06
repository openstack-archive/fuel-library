require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/openstack-network-compute.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    metadata_host    = Noop.node_hash['internal_address'] # TODO: smakar change AFTER https://bugs.launchpad.net/fuel/+bug/1486048
    use_neutron      = Noop.hiera 'use_neutron'
    service_endpoint = Noop.hiera 'service_endpoint'

    let(:memcached_servers) { Noop.hiera 'memcached_servers' }

    it 'should declare openstack::network with use_stderr disabled' do
      should contain_class('openstack::network').with(
        'use_stderr' => 'false',
      )
    end

    it 'should apply kernel tweaks for connections' do
      should contain_sysctl__value('net.ipv4.neigh.default.gc_thresh1').with_value('1024')
      should contain_sysctl__value('net.ipv4.neigh.default.gc_thresh2').with_value('2048')
      should contain_sysctl__value('net.ipv4.neigh.default.gc_thresh3').with_value('4096')
    end

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

      it 'should configure identity uri for neutron' do
        should contain_class('openstack::network').with(
         'identity_uri' => "http://#{service_endpoint}:35357",
        )
      end

      it 'should configure auth url for neutron' do
        should contain_class('openstack::network').with(
         'auth_url' => "http://#{service_endpoint}:5000",
        )
      end

      it 'should configure report_interval for neutron' do
        should contain_class('neutron').with(
          'report_interval' => '10',
        )
      end

      it 'should configure auth region for neutron-agents' do
        should contain_class('openstack::network::neutron_agents').with(
         'auth_region' => 'RegionOne',
        )
      end

      it 'should declare neutron::agents::ml2::ovs with drop_flows_on_start disabled' do
        should contain_class('neutron::agents::ml2::ovs').with(
         'drop_flows_on_start' => 'false',
        )
      end

      it 'should declare neutron::agents::ml2::ovs with prevent_arp_spoofing enabled' do
        should contain_class('neutron::agents::ml2::ovs').with(
          'prevent_arp_spoofing' => 'true',
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
      it 'should wait for integration bridge' do
        should contain_exec('wait-for-int-br').with(
          'command' => 'ovs-vsctl br-exists br-int',
        )
      end
      it { should contain_class('openstack::network').that_comes_before('Exec[wait-for-int-br]') }
      it { should contain_exec('wait-for-int-br').that_comes_before('Service[nova-compute]') }
      it 'should remove default libvirt network' do
        should contain_exec('destroy_libvirt_default_network').with(
          'command' => 'virsh net-destroy default',
          'onlyif'  => 'virsh net-info default | grep -qE "Active:.* yes"',
          'path'    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
          'tries'   => 3,
          'require' => 'Service[libvirt]',
        )

        should contain_exec('undefine_libvirt_default_network').with(
          'command' => 'virsh net-undefine default',
          'onlyif'  => 'virsh net-info default 2>&1 > /dev/null',
          'path'    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
          'tries'   => 3,
          'require' => 'Exec[destroy_libvirt_default_network]',
        )

        should contain_service('libvirt').that_notifies('Exec[destroy_libvirt_default_network]')
      end

      it 'should configure libvirt for qemu' do
        should contain_file_line('clear_emulator_capabilities').with(
          'path'    => '/etc/libvirt/qemu.conf',
          'line'    => 'clear_emulator_capabilities = 0',
        )
        should contain_file_line('no_qemu_selinux').with(
          'path'    => '/etc/libvirt/qemu.conf',
          'line'    => 'security_driver = "none"',
       )
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

      it 'should configure keystone_authtoken memcached_servers' do
        should contain_neutron_config('keystone_authtoken/memcached_servers').with_value(memcached_servers.join(','))
      end

      neutron_config =  Noop.hiera_structure 'quantum_settings'
      neutron_advanced_config =  Noop.hiera_structure 'neutron_advanced_configuration'

      if neutron_advanced_config && neutron_advanced_config.has_key?('neutron_dvr')
        dvr = neutron_advanced_config['neutron_dvr']
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

      if neutron_advanced_config && neutron_advanced_config.has_key?('neutron_l2_pop')
        l2_pop = neutron_advanced_config['neutron_l2_pop']
        it 'should configure neutron L2 population' do
           should contain_class('openstack::network').with(
             'l2_population' => l2_pop,
           )
        end
      end

      if neutron_config && neutron_config.has_key?('L2') && neutron_config['L2']['segmentation_type'] != 'vlan'
        tunnel_id_ranges = [neutron_config['L2']['tunnel_id_ranges']]
        if neutron_config['L2']['segmentation_type'] == 'gre'
          tenant_network_types  = ['flat', 'vlan', 'gre']
          tunnel_types = ['gre']
        else
          tenant_network_types  = ['flat', 'vlan', 'vxlan']
          tunnel_types = ['vxlan']
        end
        it 'should configure tunnel_types for neutron and set net_mtu' do
           should contain_class('openstack::network').with(
             'tunnel_types'         => tunnel_types,
             'tunnel_id_ranges'     => tunnel_id_ranges,
             'vni_ranges'           => tunnel_id_ranges,
             'tenant_network_types' => tenant_network_types,
             'net_mtu'              => 1500,
             'network_device_mtu'   => 1450,
           )
           should contain_class('neutron::plugins::ml2').with(
             'tunnel_id_ranges'     => tunnel_id_ranges,
             'vni_ranges'           => tunnel_id_ranges,
             'tenant_network_types' => tenant_network_types,
           )
           should contain_class('neutron::agents::ml2::ovs').with(
             'tunnel_types'     => tunnel_types ? tunnel_types.join(",") : "",
           )
        end
      else
          it 'should declare openstack::network with tunnel_types set to [] and set net_mtu' do
            should contain_class('openstack::network').with(
              'tunnel_types'       => [],
              'net_mtu'            => 1500,
              'network_device_mtu' => 1500,
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
          'value' => metadata_host,
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

