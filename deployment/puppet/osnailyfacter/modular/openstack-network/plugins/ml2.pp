notice('MODULAR: openstack-network/plugins/ml2.pp')

$use_neutron = hiera('use_neutron', false)

class neutron {}
class { 'neutron' :}

if $use_neutron {
  include ::neutron::params

  $role = hiera('role')
  $controller = $role in ['controller', 'primary-controller']

  $neutron_config = hiera_hash('neutron_config')
  $neutron_server_enable = pick($neutron_config['neutron_server_enable'], true)

  $auth_password      = $neutron_config['keystone']['admin_password']
  $auth_user          = pick($neutron_config['keystone']['admin_user'], 'neutron')
  $auth_tenant        = pick($neutron_config['keystone']['admin_tenant'], 'services')
  $auth_region        = hiera('region', 'RegionOne')
  $auth_endpoint_type = 'internalURL'

  $network_scheme = hiera_hash('network_scheme')
  prepare_network_config($network_scheme)

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $ha_agent          = try_get_value($neutron_advanced_config, 'l2_agent_ha', true)
  $l2_population     = try_get_value($neutron_advanced_config, 'neutron_l2_pop', false)
  $dvr               = try_get_value($neutron_advanced_config, 'neutron_dvr', false)
  $segmentation_type = try_get_value($neutron_config, 'L2/segmentation_type')

  if $segmentation_type == 'vlan' {
    $net_role_property    = 'neutron/private'
    $iface                = get_network_role_property($net_role_property, 'phys_dev')
    $physical_net_mtu = pick(get_transformation_property('mtu', $iface[0]), '1500')
    $overlay_net_mtu      = $physical_net_mtu
    $enable_tunneling = false
    $network_vlan_ranges_physnet2 = try_get_value($neutron_config, 'L2/phys_nets/physnet2/vlan_range')
    $network_vlan_ranges = ["physnet2:${$network_vlan_ranges_physnet2}"]
    $physnet2_bridge = try_get_value($neutron_config, 'L2/phys_nets/physnet2/bridge')
    $physnet2 = "physnet2:${physnet2_bridge}"
    $bridge_mappings = [$physnet2]
    $physical_network_mtus = ["physnet2:${physical_net_mtu}"]
    $tunnel_id_ranges = []
    $network_type = 'vlan'
  } else {
    $net_role_property = 'neutron/mesh'
    $tunneling_ip      = get_network_role_property($net_role_property, 'ipaddr')
    $iface             = get_network_role_property($net_role_property, 'phys_dev')
    $physical_net_mtu  = pick(get_transformation_property('mtu', $iface[0]), '1500')
    $tunnel_id_ranges  = [try_get_value($neutron_config, 'L2/tunnel_id_ranges')]
    $network_vlan_ranges   = []
    $physical_network_mtus = []

    if $segmentation_type == 'gre' {
      $mtu_offset = '42'
      $network_type = 'gre'
    } else {
      # vxlan is the default segmentation type for non-vlan cases
      $mtu_offset = '50'
      $network_type = 'vxlan'
    }

    if $physical_net_mtu {
      $overlay_net_mtu = $physical_net_mtu - $mtu_offset
    } else {
      $overlay_net_mtu = '1500' - $mtu_offset
    }

    $enable_tunneling = true
    $tunnel_types = [$network_type]
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

  # Neutron_plugin_ml2<||> -> Service['neutron-server']
  # Neutron_agent_ovs<||> -> Service['neutron-server']
  service { 'neutron-server':
    name       => $::neutron::params::server_service,
    enable     => $neutron_server_enable,
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

  if $ha_agent {
    $primary_controller = hiera('primary_controller')
    Exec<| title == 'waiting-for-neutron-api' |> ->
    class { 'cluster::neutron::ovs' :
      primary => $primary_controller,
    }
  }

  #========================
  package { 'neutron':
    name   => 'binutils',
    ensure => 'installed',
  }

}
