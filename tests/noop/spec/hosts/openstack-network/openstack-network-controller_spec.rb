require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/openstack-network-controller.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    use_neutron = Noop.hiera 'use_neutron'
    ceilometer_enabled = Noop.hiera_structure 'ceilometer/enabled'
    service_endpoint   = Noop.hiera 'service_endpoint'

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
      it 'should declare openstack::network with neutron enabled' do
        should contain_class('openstack::network').with(
          'neutron_server' => 'true',
        )
      end

      it 'should declare neutron::agents::ml2::ovs with manage_service enabled' do
        should contain_class('neutron::agents::ml2::ovs').with(
          'manage_service' => 'true',
        )
      end

      it 'should declare neutron::agents::ml2::ovs with prevent_arp_spoofing enabled' do
        should contain_class('neutron::agents::ml2::ovs').with(
          'prevent_arp_spoofing' => 'true',
        )
      end

      it 'should declare neutron::agents::dhcp with isolated metadata enabled' do
        should contain_class('neutron::agents::dhcp').with(
         'enable_isolated_metadata' => 'true',
        )
      end

      it 'should declare neutron::agents::l3 with router_delete_namespaces enabled' do
        should contain_class('neutron::agents::l3').with(
         'router_delete_namespaces' => 'true',
        )
      end

      it 'should declare neutron::agents::dhcp with dhcp_delete_namespaces enabled' do
        should contain_class('neutron::agents::dhcp').with(
         'dhcp_delete_namespaces' => 'true',
        )
      end

      it 'should declare neutron::agents::ml2::ovs with drop_flows_on_start disabled' do
        should contain_class('neutron::agents::ml2::ovs').with(
         'drop_flows_on_start' => 'false',
        )
      end

      it 'should pass auth region to openstack::network' do
        should contain_class('openstack::network').with(
         'region' => 'RegionOne',
        )
      end

      it 'should configure auth region for neutron-server' do
        should contain_class('neutron::server').with(
         'auth_region' => 'RegionOne',
        )
      end

      it 'should configure auth region for neutron-server-notifications' do
        should contain_class('neutron::server::notifications').with(
         'nova_region_name' => 'RegionOne',
        )
      end

      it 'should configure auth region for neutron-agents' do
        should contain_class('openstack::network::neutron_agents').with(
         'auth_region' => 'RegionOne',
        )
      end

      it 'should configure agent_down_time for neutron-server' do
        should contain_class('neutron::server').with(
          'agent_down_time' => '30',
        )
      end

      it 'should configure report_interval for neutron' do
        should contain_class('neutron').with(
          'report_interval' => '10',
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
          it 'should set dvr_snat mode for neutron l3 agent' do
             should contain_class('openstack::network::neutron_agents').with(
               'agent_mode' => 'dvr_snat',
             )
          end
        else
          it 'should set legacy mode for neutron l3 agent' do
             should contain_class('openstack::network::neutron_agents').with(
               'agent_mode' => 'legacy',
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
              'tunnel_types'         => [],
              'net_mtu'              => 1500,
              'network_device_mtu'   => 1500,
            )
          end
      end
    else
      it 'should declare openstack::network with neutron disabled' do
        should contain_class('openstack::network').with(
          'neutron_server' => 'false',
        )
      end
    end

    # Ceilometer
    if ceilometer_enabled and use_neutron
      it 'should configure notification_driver for neutron' do
        should contain_neutron_config('DEFAULT/notification_driver').with(
          'value' => 'messaging',
        )
      end
    end

    if !use_neutron
      nameservers = Noop.hiera 'dns_nameservers'
      if nameservers
        it 'should declare nova::network with nameservers' do
          should contain_class('nova::network').with(
            'nameservers' => nameservers,
          )
        end
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

