class openstack_tasks::openstack_network::server_config {

  notice('MODULAR: openstack_network/server_config.pp')

  $use_neutron = hiera('use_neutron', false)

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

  if $use_neutron {

    $neutron_config          = hiera_hash('neutron_config')
    $neutron_server_enable   = pick($neutron_config['neutron_server_enable'], true)
    $database_vip            = hiera('database_vip')
    $nova_hash               = hiera_hash('nova', { })
    $pci_vendor_devs         = $neutron_config['supported_pci_vendor_devs']

    $neutron_primary_controller_roles = hiera('neutron_primary_controller_roles', ['primary-controller'])
    $neutron_compute_roles            = hiera('neutron_compute_nodes', ['compute'])
    $primary_controller               = roles_include($neutron_primary_controller_roles)
    $compute                          = roles_include($neutron_compute_roles)

    $db_type     = 'mysql'
    $db_password = $neutron_config['database']['passwd']
    $db_user     = try_get_value($neutron_config, 'database/user', 'neutron')
    $db_name     = try_get_value($neutron_config, 'database/name', 'neutron')
    $db_host     = try_get_value($neutron_config, 'database/host', $database_vip)
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

    $ssl_hash                = hiera_hash('use_ssl', {})
    $management_vip          = hiera('management_vip')
    $nova_endpoint           = hiera('nova_endpoint', $management_vip)

    $nova_internal_protocol  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', 'http')
    $nova_internal_endpoint  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$nova_endpoint])

    $auth_uri                = hiera('internal_auth_uri')
    $identity_uri            = hiera('admin_identity_uri')

    $nova_url                = "${nova_internal_protocol}://${nova_internal_endpoint}:8774/v2"

    $workers_max             = hiera('workers_max', 16)
    $service_workers         = pick($neutron_config['workers'], min(max($::processorcount, 2), $workers_max))

    $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
    $l2_population           = try_get_value($neutron_advanced_config, 'neutron_l2_pop', false)
    $dvr                     = pick($neutron_advanced_config['neutron_dvr'], false)
    $l3_ha                   = pick($neutron_advanced_config['neutron_l3_ha'], false)
    $l3agent_failover        = $l3_ha ? { true => false, default => true}
    $enable_qos              = pick($neutron_advanced_config['neutron_qos'], false)

    if $enable_qos {
      $qos_notification_drivers = 'message_queue'
      $extension_drivers = ['port_security', 'qos']
    } else {
      $qos_notification_drivers = undef
      $extension_drivers = ['port_security']
    }

    $nova_auth_user          = pick($nova_hash['user'], 'nova')
    $nova_auth_password      = $nova_hash['user_password']
    $nova_auth_tenant        = pick($nova_hash['tenant'], 'services')

    $type_drivers              = ['local', 'flat', 'vlan', 'gre', 'vxlan']
    $default_mechanism_drivers = ['openvswitch']
    $l2_population_mech_driver = $l2_population ? { true => ['l2population'], default => []}
    $sriov_mech_driver         = $use_sriov ? { true => ['sriovnicswitch'], default => []}
    $mechanism_drivers         = delete(try_get_value($neutron_config, 'L2/mechanism_drivers', concat($default_mechanism_drivers,$l2_population_mech_driver,$sriov_mech_driver)), '')
    $flat_networks             = ['*']
    $segmentation_type         = try_get_value($neutron_config, 'L2/segmentation_type')

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

    if $segmentation_type == 'vlan' {
      $net_role_property    = 'neutron/private'
      $iface                = get_network_role_property($net_role_property, 'phys_dev')
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
    } else {
      $net_role_property = 'neutron/mesh'
      $tunneling_ip      = get_network_role_property($net_role_property, 'ipaddr')
      $iface             = get_network_role_property($net_role_property, 'phys_dev')
      $tunnel_id_ranges  = [try_get_value($neutron_config, 'L2/tunnel_id_ranges')]
      $physical_network_mtus = generate_physnet_mtus($neutron_config, $network_scheme, {
        'do_floating' => $do_floating,
        'do_tenant'   => false,
        'do_provider' => false
      })
      $network_vlan_ranges = []

      if $segmentation_type == 'gre' {
        $network_type = 'gre'
      } else {
        # vxlan is the default segmentation type for non-vlan cases
        $network_type = 'vxlan'
      }
    }

    $physical_net_mtu = pick(get_transformation_property('mtu', $iface[0]), '1500')

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
      path_mtu                  => $physical_net_mtu,
      extension_drivers         => $extension_drivers,
      supported_pci_vendor_devs => $pci_vendor_devs,
      sriov_agent_required      => $use_sriov,
      enable_security_group     => true,
      firewall_driver           => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
    }

    # TODO(Xarses): Uhh.. what? why are auth_uri and auth_url different to neutron?
    # https://bugs.launchpad.net/fuel/+bug/1568080
    class { '::neutron::server':
      sync_db                          => $primary_controller,

      username                         => $username,
      password                         => $password,
      project_name                     => $project_name,
      region_name                      => $region_name,
      auth_url                         => $identity_uri,
      auth_uri                         => $auth_uri,

      database_connection              => $db_connection,
      database_max_retries             => hiera('max_retries'),
      database_idle_timeout            => hiera('idle_timeout'),
      database_max_pool_size           => hiera('max_pool_size'),
      database_max_overflow            => hiera('max_overflow'),
      database_retry_interval          => '2',

      agent_down_time                  => $neutron_config['neutron_agent_down_time'],
      allow_automatic_l3agent_failover => $l3agent_failover,
      l3_ha                            => $l3_ha,
      min_l3_agents_per_router         => 2,
      max_l3_agents_per_router         => 0,

      api_workers                      => $service_workers,
      rpc_workers                      => $service_workers,

      router_distributed               => $dvr,
      qos_notification_drivers         => $qos_notification_drivers,
      enabled                          => true,
      manage_service                   => true,
    }

    include ::neutron::params
    tweaks::ubuntu_service_override { $::neutron::params::server_service:
      package_name => $neutron::params::server_package ? {
        false   => $neutron::params::package_name,
        default => $neutron::params::server_package
      }
    }

    class { '::neutron::server::notifications':
      nova_url     => $nova_url,
      auth_url     => $identity_uri,
      username     => $nova_auth_user,
      project_name => $nova_auth_tenant,
      password     => $nova_auth_password,
      region_name  => $region_name,
    }

    # Stub for Nuetron package
    package { 'neutron':
      name   => 'binutils',
      ensure => 'installed',
    }

  }

}
