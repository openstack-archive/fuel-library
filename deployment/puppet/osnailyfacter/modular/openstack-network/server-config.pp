notice('MODULAR: openstack-network/server-config.pp')

$use_neutron = hiera('use_neutron', false)
$compute     = roles_include('compute')

if $use_neutron {
  # override neutron options
  $override_configuration = hiera_hash('configuration', {})
  override_resources { 'neutron_api_config':
    data => $override_configuration['neutron_api_config']
  } ~> Service['neutron-server']
  override_resources { 'neutron_config':
    data => $override_configuration['neutron_config']
  } ~> Service['neutron-server']
  override_resources { 'neutron_plugin_ml2':
    data => $override_configuration['neutron_plugin_ml2']
  } ~> Service['neutron-server']
}

class neutron { }
class { 'neutron' : }

if $use_neutron {

  $neutron_config          = hiera_hash('neutron_config')
  $neutron_server_enable   = pick($neutron_config['neutron_server_enable'], true)
  $database_vip            = hiera('database_vip')
  $management_vip          = hiera('management_vip')
  $service_endpoint        = hiera('service_endpoint', $management_vip)
  $nova_endpoint           = hiera('nova_endpoint', $management_vip)
  $nova_hash               = hiera_hash('nova', { })

  $neutron_db_password     = $neutron_config['database']['passwd']
  $neutron_db_user         = try_get_value($neutron_config, 'database/user', 'neutron')
  $neutron_db_name         = try_get_value($neutron_config, 'database/name', 'neutron')
  $neutron_db_host         = try_get_value($neutron_config, 'database/host', $database_vip)

  $neutron_db_uri          = "mysql://${neutron_db_user}:${neutron_db_password}@${neutron_db_host}/${neutron_db_name}?&read_timeout=60"

  $auth_password           = $neutron_config['keystone']['admin_password']
  $auth_user               = pick($neutron_config['keystone']['admin_user'], 'neutron')
  $auth_tenant             = pick($neutron_config['keystone']['admin_tenant'], 'services')
  $auth_region             = hiera('region', 'RegionOne')
  $auth_endpoint_type      = 'internalURL'
  $memcached_servers       = hiera('memcached_servers')

  $ssl_hash                = hiera_hash('use_ssl', {})

  $internal_auth_protocol  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_endpoint  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])

  $admin_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_auth_endpoint     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])

  $nova_internal_protocol  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', 'http')
  $nova_internal_endpoint  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$nova_endpoint])

  $auth_api_version        = 'v2.0'
  $identity_uri            = "${internal_auth_protocol}://${internal_auth_endpoint}:5000/"
  $nova_admin_auth_url     = "${admin_auth_protocol}://${admin_auth_endpoint}:35357/"
  $nova_url                = "${nova_internal_protocol}://${nova_internal_endpoint}:8774/v2"

  $workers_max             = hiera('workers_max', 16)
  $service_workers         = pick($neutron_config['workers'], min(max($::processorcount, 2), $workers_max))

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $l2_population           = try_get_value($neutron_advanced_config, 'neutron_l2_pop', false)
  $dvr                     = pick($neutron_advanced_config['neutron_dvr'], false)
  $l3_ha                   = pick($neutron_advanced_config['neutron_l3_ha'], false)
  $l3agent_failover        = $l3_ha ? { true => false, default => true}

  $nova_auth_user          = pick($nova_hash['user'], 'nova')
  $nova_auth_password      = $nova_hash['user_password']
  $nova_auth_tenant        = pick($nova_hash['tenant'], 'services')

  $type_drivers = ['local', 'flat', 'vlan', 'gre', 'vxlan']
  $default_mechanism_drivers = $l2_population ? { true => 'openvswitch,l2population', default => 'openvswitch'}
  $mechanism_drivers = split(try_get_value($neutron_config, 'L2/mechanism_drivers', $default_mechanism_drivers), ',')
  $flat_networks = ['*']
  $segmentation_type = try_get_value($neutron_config, 'L2/segmentation_type')

  $network_scheme = hiera_hash('network_scheme')
  prepare_network_config($network_scheme)

  if $segmentation_type == 'vlan' {
    $net_role_property    = 'neutron/private'
    $iface                = get_network_role_property($net_role_property, 'phys_dev')
    $overlay_net_mtu      =  pick(get_transformation_property('mtu', $iface[0]), '1500')
    $physical_network_mtus = generate_physnet_mtus($neutron_config, $network_scheme, {
      'do_floating' => $do_floating,
      'do_tenant'   => true,
      'do_provider' => false
    })
    $network_vlan_ranges = generate_physnet_vlan_ranges($neutron_config, $network_scheme, {
      'do_floating' => $do_floating,
      'do_tenant'   => true,
      'do_provider' => false
    })
    $tunnel_id_ranges = []
    $network_type = 'vlan'
    $tunnel_types = []
  } else {
    $net_role_property = 'neutron/mesh'
    $tunneling_ip      = get_network_role_property($net_role_property, 'ipaddr')
    $iface             = get_network_role_property($net_role_property, 'phys_dev')
    $physical_net_mtu  = pick(get_transformation_property('mtu', $iface[0]), '1500')
    $tunnel_id_ranges  = [try_get_value($neutron_config, 'L2/tunnel_id_ranges')]
    $physical_network_mtus = generate_physnet_mtus($neutron_config, $network_scheme, {
      'do_floating' => $do_floating,
      'do_tenant'   => false,
      'do_provider' => false
    })
    $network_vlan_ranges = []

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
  }

  if $compute and ! $dvr {
    $do_floating = false
  } else {
    $do_floating = true
  }

  $vxlan_group = '224.0.0.1'
  $extension_drivers = ['port_security']
  $tenant_network_types  = ['flat', $network_type]

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

  class { 'neutron::server':
    sync_db                          =>  false,

    auth_password                    => $auth_password,
    auth_tenant                      => $auth_tenant,
    auth_region                      => $auth_region,
    auth_user                        => $auth_user,
    identity_uri                     => $identity_uri,
    auth_uri                         => $identity_uri,

    database_retry_interval          => '2',
    database_connection              => $neutron_db_uri,
    database_max_retries             => '-1',

    agent_down_time                  => '30',
    allow_automatic_l3agent_failover => $l3agent_failover,
    l3_ha                            => $l3_ha,
    min_l3_agents_per_router         => 2,
    max_l3_agents_per_router         => 0,

    api_workers                      => $service_workers,
    rpc_workers                      => $service_workers,

    router_distributed               => $dvr,
    enabled                          => true,
    manage_service                   => true,
  }

  neutron_config {
    'keystone_authtoken/memcached_servers' : value => join(any2array($memcached_servers), ',');
  }

  include neutron::params
  tweaks::ubuntu_service_override { "$::neutron::params::server_service":
    package_name => $neutron::params::server_package ? {
      false   => $neutron::params::package_name,
      default => $neutron::params::server_package
    }
  }

  class { 'neutron::server::notifications':
    nova_url     => $nova_url,
    auth_url     => $nova_admin_auth_url,
    username     => $nova_auth_user,
    tenant_name  => $nova_auth_tenant,
    password     => $nova_auth_password,
    region_name  => $auth_region,
  }

  # Stub for Nuetron package
  package { 'neutron':
    name   => 'binutils',
    ensure => 'installed',
  }

}
