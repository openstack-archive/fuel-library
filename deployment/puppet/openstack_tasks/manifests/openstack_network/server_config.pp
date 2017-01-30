class openstack_tasks::openstack_network::server_config {

  notice('MODULAR: openstack_network/server_config.pp')

  $neutron_config          = hiera_hash('neutron_config')
  $neutron_server_enable   = pick($neutron_config['neutron_server_enable'], true)
  $database_vip            = hiera('database_vip')
  $management_vip          = hiera('management_vip')
  $service_endpoint        = hiera('service_endpoint', $management_vip)
  $nova_endpoint           = hiera('nova_endpoint', $management_vip)
  $nova_hash               = hiera_hash('nova', { })
  $pci_vendor_devs         = $neutron_config['supported_pci_vendor_devs']

  $neutron_compute_roles = hiera('neutron_compute_nodes', ['compute'])
  $primary_neutron       = has_primary_role(intersection(hiera('neutron_roles'), hiera('roles')))
  $compute               = roles_include($neutron_compute_roles)

  $db_type     = try_get_value($neutron_config, 'database/type', 'mysql+pymysql')
  $db_password = $neutron_config['database']['passwd']
  $db_user     = dig44($neutron_config, ['database', 'user'], 'neutron')
  $db_name     = dig44($neutron_config, ['database', 'name'], 'neutron')
  $db_host     = dig44($neutron_config, ['database', 'host'], $database_vip)
  # LP#1526938 - python-mysqldb supports this, python-pymysql does not
  if $::os_package_type == 'debian' {
    $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
  } else {
    $extra_params = { 'charset' => 'utf8' }
  }
  $db_connection = os_database_connection({
    'dialect'  => $db_type,
    'host'     => $db_host,
    'database' => $db_name,
    'username' => $db_user,
    'password' => $db_password,
    'extra'    => $extra_params
  })

  if $pci_vendor_devs {
    # Boolean value for further usage
    $use_sriov = true
    $ml2_sriov_value = 'set DAEMON_ARGS \'"$DAEMON_ARGS --config-file /etc/neutron/plugins/ml2/ml2_conf_sriov.ini"\''
  } else {
    $use_sriov = false
    $ml2_sriov_value = 'rm DAEMON_ARGS'
  }

  $password                = $neutron_config['keystone']['admin_password']
  $username                = pick($neutron_config['keystone']['admin_user'], 'neutron')
  $project_name            = pick($neutron_config['keystone']['admin_tenant'], 'services')
  $region_name             = hiera('region', 'RegionOne')
  $auth_endpoint_type      = 'internalURL'
  $memcached_servers       = hiera('memcached_servers')
  $local_memcached_server = hiera('local_memcached_server')

  $ssl_hash                = hiera_hash('use_ssl', {})

  $internal_auth_protocol  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_endpoint  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])

  $admin_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_auth_endpoint     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])

  $auth_api_version        = 'v2.0'
  $auth_uri                = "${internal_auth_protocol}://${internal_auth_endpoint}:5000/"
  $auth_url                = "${internal_auth_protocol}://${internal_auth_endpoint}:35357/"
  $nova_admin_auth_url     = "${admin_auth_protocol}://${admin_auth_endpoint}:35357/"

  $workers_max             = hiera('workers_max', $::os_workers)
  $service_workers         = pick($neutron_config['workers'], min(max($::processorcount, 1), $workers_max))

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $l2_population           = dig44($neutron_advanced_config, ['neutron_l2_pop'], false)
  $dvr                     = pick($neutron_advanced_config['neutron_dvr'], false)
  $l3_ha                   = pick($neutron_advanced_config['neutron_l3_ha'], false)
  $l3agent_failover        = $l3_ha ? { true => false, default => true}
  $enable_qos              = pick($neutron_advanced_config['neutron_qos'], false)

  if $enable_qos {
    $qos_notification_drivers = 'message_queue'
    $extension_drivers = ['dns', 'port_security', 'qos']
  } else {
    $qos_notification_drivers = undef
    $extension_drivers = ['dns', 'port_security']
  }

  $nova_auth_user          = pick($nova_hash['user'], 'nova')
  $nova_auth_password      = $nova_hash['user_password']
  $nova_auth_tenant        = pick($nova_hash['tenant'], 'services')

  $type_drivers              = ['local', 'flat', 'vlan', 'gre', 'vxlan']
  $default_mechanism_drivers = ['openvswitch']
  $l2_population_mech_driver = $l2_population ? { true => ['l2population'], default => []}
  $sriov_mech_driver         = $use_sriov ? { true => ['sriovnicswitch'], default => []}
  $mechanism_drivers         = delete(dig44($neutron_config, ['L2', 'mechanism_drivers'], concat($default_mechanism_drivers,$l2_population_mech_driver,$sriov_mech_driver)), '')
  $flat_networks             = ['*']
  $segmentation_type         = dig44($neutron_config, ['L2', 'segmentation_type'])

  $network_scheme = hiera_hash('network_scheme', {})
  prepare_network_config($network_scheme)

  if ! $compute and $::osfamily == 'Debian' {
    augeas { '/etc/default/neutron-server:ml2_sriov_config':
      context => '/files/etc/default/neutron-server',
      changes => $ml2_sriov_value,
      notify  => Service['neutron-server'],
    }
    Class['::neutron::plugins::ml2'] -> Augeas['/etc/default/neutron-server:ml2_sriov_config']
  }

  $_path_mtu = dig44($neutron_config, ['L2', 'path_mtu'], undef)

  if $segmentation_type == 'vlan' {
    $net_role_property    = 'neutron/private'
    $physical_network_mtus = generate_physnet_mtus($neutron_config, $network_scheme, {
      'do_floating' => $do_floating,
      'do_tenant'   => true,
      'do_provider' => false
    })

    if ! empty($_path_mtu) {
      $path_mtu = $_path_mtu
    } else {
      $path_mtu = undef
    }

    $network_vlan_ranges = generate_physnet_vlan_ranges($neutron_config, $network_scheme, {
      'do_floating' => $do_floating,
      'do_tenant'   => true,
      'do_provider' => false
    })
    $tunnel_id_ranges = []
    $network_type = 'vlan'
  } else {
    $net_role_property = 'neutron/mesh'
    $tunneling_ip      = get_network_role_property($net_role_property, 'ipaddr')
    $iface             = get_network_role_property($net_role_property, 'phys_dev')
    $tunnel_id_ranges  = [dig44($neutron_config, ['L2', 'tunnel_id_ranges'])]
    $physical_network_mtus = generate_physnet_mtus($neutron_config, $network_scheme, {
      'do_floating' => $do_floating,
      'do_tenant'   => false,
      'do_provider' => false
    })
    $network_vlan_ranges = []

    if ! empty($_path_mtu) {
      $path_mtu = $_path_mtu
    } else {
      $path_mtu = pick(get_transformation_property('mtu', $iface[0]), '1500')
    }

    if $segmentation_type == 'gre' {
      $network_type = 'gre'
    } else {
      # vxlan is the default segmentation type for non-vlan cases
      $network_type = 'vxlan'
    }
  }

  if $compute and ! $dvr {
    $do_floating = false
  } else {
    $do_floating = true
  }

  $vxlan_group = '224.0.0.1'
  $tenant_network_types  = ['flat', $network_type]

  class { '::neutron::plugins::ml2':
    type_drivers              => $type_drivers,
    tenant_network_types      => $tenant_network_types,
    mechanism_drivers         => $mechanism_drivers,
    flat_networks             => $flat_networks,
    network_vlan_ranges       => $network_vlan_ranges,
    tunnel_id_ranges          => $tunnel_id_ranges,
    vxlan_group               => $vxlan_group,
    vni_ranges                => $tunnel_id_ranges,
    physical_network_mtus     => $physical_network_mtus,
    path_mtu                  => $path_mtu,
    extension_drivers         => $extension_drivers,
    supported_pci_vendor_devs => $pci_vendor_devs,
    enable_security_group     => true,
    firewall_driver           => hiera('security_groups', 'iptables_hybrid'),
  }

  class { '::neutron::keystone::authtoken':
    username          => $username,
    password          => $password,
    project_name      => $project_name,
    region_name       => $region_name,
    auth_url          => $auth_url,
    auth_uri          => $auth_uri,
    memcached_servers => $local_memcached_server,
  }

  class { '::neutron::server':
    sync_db                          => $primary_neutron,

    auth_strategy                    => 'keystone',

    database_connection              => $db_connection,
    database_max_retries             => hiera('max_retries'),
    database_idle_timeout            => hiera('idle_timeout'),
    database_max_pool_size           => hiera('max_pool_size'),
    database_max_overflow            => hiera('max_overflow'),
    database_retry_interval          => '2',

    agent_down_time                  => $neutron_config['neutron_agent_down_time'],
    allow_automatic_l3agent_failover => $l3agent_failover,
    l3_ha                            => $l3_ha,
    max_l3_agents_per_router         => 0,

    api_workers                      => $service_workers,
    rpc_workers                      => $service_workers,

    router_distributed               => $dvr,
    qos_notification_drivers         => $qos_notification_drivers,
    enabled                          => true,
    manage_service                   => true,
  }

  # TODO(mmalchuk) remove this after LP#1628580 merged
  Exec<| title == 'neutron-db-sync' |> {
    tries     => '10',
    try_sleep => '5'
  }

  include ::neutron::params
  tweaks::ubuntu_service_override { $::neutron::params::server_service:
    package_name => $neutron::params::server_package ? {
      false   => $neutron::params::package_name,
      default => $neutron::params::server_package
    }
  }

  class { '::neutron::server::notifications':
    auth_url     => $nova_admin_auth_url,
    username     => $nova_auth_user,
    project_name => $nova_auth_tenant,
    password     => $nova_auth_password,
    region_name  => $region_name,
  }

  # Stub for Neutron package
  package { 'neutron':
    name   => 'binutils',
    ensure => 'installed',
  }

  if is_file_updated('/etc/neutron/neutron.conf', $title) {
    notify{'neutron.conf has been changed, going to restart neutron server':
    } ~> Service['neutron-server']
  }
}
