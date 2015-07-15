require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/openstack-network-controller.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    use_neutron = Noop.hiera 'use_neutron'
    ceilometer_enabled = Noop.hiera_structure 'ceilometer/enabled'

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

      it 'should declare neutron::agents::dhcp with isolated metadata enabled' do
        should contain_class('neutron::agents::dhcp').with(
         'enable_isolated_metadata' => 'true',
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

      neutron_config =  Noop.hiera_structure 'quantum_settings'

      if neutron_config && neutron_config.has_key?('L2') && neutron_config['L2']['segmentation_type'] != 'vlan'
        tunnel_id_ranges = [neutron_config['L2']['tunnel_id_ranges']]
        if neutron_config['L2'].has_key?('use_gre_for_tun') && neutron_config['L2']['use_gre_for_tun']
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
             'net_mtu'              => '1450',
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
              'tunnel_types' => [],
              'net_mtu'      => nil,
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

