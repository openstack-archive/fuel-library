notice('MODULAR: openstack-network/plugins/ml2.pp')

$use_neutron = hiera('use_neutron', false)

class neutron {}
class { 'neutron' :}

if $use_neutron {
  include ::neutron::params

  $roles = hiera('roles')
  $node_name = hiera('node_name')
  $primary_controller = member($roles,'primary-controller')

  $neutron_config = hiera_hash('neutron_config')
  $neutron_server_enable = pick($neutron_config['neutron_server_enable'], true)
  $neutron_nodes = hiera_hash('neutron_nodes')

  $management_vip     = hiera('management_vip')
  $service_endpoint   = hiera('service_endpoint', $management_vip)
  $auth_api_version   = 'v2.0'
  $identity_uri       = "http://${service_endpoint}:5000"
  $auth_url           = "${identity_uri}/${auth_api_version}"
  $auth_password      = $neutron_config['keystone']['admin_password']
  $auth_user          = pick($neutron_config['keystone']['admin_user'], 'neutron')
  $auth_tenant        = pick($neutron_config['keystone']['admin_tenant'], 'services')
  $auth_region        = hiera('region', 'RegionOne')
  $auth_endpoint_type = 'internalURL'

  $network_scheme = hiera_hash('network_scheme')
  prepare_network_config($network_scheme)

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $l2_population     = try_get_value($neutron_advanced_config, 'neutron_l2_pop', false)
  $dvr               = try_get_value($neutron_advanced_config, 'neutron_dvr', false)
  $segmentation_type = try_get_value($neutron_config, 'L2/segmentation_type')
  $extension_drivers = ['port_security']

  if $compute and ! $dvr {
    $do_floating = false
  } else {
    $do_floating = true
  }

  $bridge_mappings = generate_bridge_mappings($neutron_config, $network_scheme, {
    'do_floating' => $do_floating,
    'do_tenant'   => true,
    'do_provider' => false
  })
  $network_vlan_ranges = generate_physnet_vlan_ranges($neutron_config, $network_scheme, {
    'do_floating' => $do_floating,
    'do_tenant'   => true,
    'do_provider' => false
  })

  if $segmentation_type == 'vlan' {
    $net_role_property    = 'neutron/private'
    $iface                = get_network_role_property($net_role_property, 'phys_dev')
    $physical_net_mtu = pick(get_transformation_property('mtu', $iface[0]), '1500')
    $overlay_net_mtu      = $physical_net_mtu
    $enable_tunneling = false
    $physnet2_bridge = try_get_value($neutron_config, 'L2/phys_nets/physnet2/bridge')
    $physnet2 = "physnet2:${physnet2_bridge}"
    $physical_network_mtus = ["physnet2:${physical_net_mtu}"]
    $tunnel_id_ranges = []
    $network_type = 'vlan'
    $tunnel_types = []
  } else {
    $net_role_property = 'neutron/mesh'
    $tunneling_ip      = get_network_role_property($net_role_property, 'ipaddr')
    $iface             = get_network_role_property($net_role_property, 'phys_dev')
    $physical_net_mtu  = pick(get_transformation_property('mtu', $iface[0]), '1500')
    $tunnel_id_ranges  = [try_get_value($neutron_config, 'L2/tunnel_id_ranges')]
    $physical_network_mtus = []

    if $segmentation_type == 'gre' {
      $mtu_offset = '42'
      $network_type = 'gre'
    } else {
      # vxlan is the default segmentation type for non-vlan cases
      $mtu_offset = '50'
      $network_type = 'vxlan'
    }
    $tunnel_types = [$network_type]

    if $physical_net_mtu {
      $overlay_net_mtu = $physical_net_mtu - $mtu_offset
    } else {
      $overlay_net_mtu = '1500' - $mtu_offset
    }

    $enable_tunneling = true
  }

  $type_drivers = ['local', 'flat', 'vlan', 'gre', 'vxlan']
  $tenant_network_types  = ['flat', $network_type]
  $mechanism_drivers = split(try_get_value($neutron_config, 'L2/mechanism_drivers', 'openvswitch,l2population'), ',')
  $flat_networks = ['*']
  $vxlan_group = '224.0.0.1'

  class { 'neutron::plugins::ml2':
    type_drivers          => $type_drivers,
    tenant_network_types  => $tenant_network_types,
    mechanism_drivers     => $mechanism_drivers,
    flat_networks         => $flat_networks,
    network_vlan_ranges   => $network_vlan_ranges,
    tunnel_id_ranges      => $tunnel_id_ranges,
    vxlan_group           => $vxlan_group,
    vni_ranges            => $tunnel_id_ranges,
    physical_network_mtus => $physical_network_mtus,
    path_mtu              => $overlay_net_mtu,
    extension_drivers     => $extension_drivers,
  }

  class { 'neutron::agents::ml2::ovs':
    bridge_mappings            => $bridge_mappings,
    enable_tunneling           => $enable_tunneling,
    local_ip                   => $tunneling_ip,
    tunnel_types               => $tunnel_types,
    enable_distributed_routing => $dvr,
    l2_population              => $l2_population,
    arp_responder              => $l2_population,
    manage_vswitch             => false,
    manage_service             => true,
    enabled                    => true,
  }

  # Synchronize database after plugin was configured
  if $primary_controller {
    include ::neutron::db::sync
  }

  if $node_name in keys($neutron_nodes) {
    if $neutron_server_enable {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
    service { 'neutron-server':
      name       => $::neutron::params::server_service,
      enable     => $neutron_server_enable,
      ensure     => $service_ensure,
      hasstatus  => true,
      hasrestart => true,
      tag        => 'neutron-service',
    } ->
    exec { 'waiting-for-neutron-api':
      environment => [
        "OS_TENANT_NAME=${auth_tenant}",
        "OS_USERNAME=${auth_user}",
        "OS_PASSWORD=${auth_password}",
        "OS_AUTH_URL=${auth_url}",
        "OS_REGION_NAME=${auth_region}",
        "OS_ENDPOINT_TYPE=${auth_endpoint_type}",
      ],
      path        => '/usr/sbin:/usr/bin:/sbin:/bin',
      tries       => '30',
      try_sleep   => '4',
      command     => 'neutron net-list --http-timeout=4 2>&1 > /dev/null',
      provider    => 'shell'
    }

    $ha_agent = try_get_value($neutron_advanced_config, 'l2_agent_ha', true)
    if $ha_agent {
      #Exec<| title == 'waiting-for-neutron-api' |> ->
      class { 'cluster::neutron::ovs' :
        primary => $primary_controller,
      }
    }
  }

  # Stub for upstream neutron manifests
  package { 'neutron':
    name   => 'binutils',
    ensure => 'installed',
  }

  # override neutron options
  $override_configuration = hiera_hash('configuration', {})
  override_resources { 'neutron_plugin_ml2':
    data => $override_configuration['neutron_plugin_ml2']
  }
  override_resources { 'neutron_agent_ovs':
    data => $override_configuration['neutron_agent_ovs']
  }

}
