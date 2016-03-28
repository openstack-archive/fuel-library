class openstack_tasks::openstack_network::common_config {

  notice('MODULAR: openstack_network/common_config.pp')

  $use_neutron = hiera('use_neutron', false)

  if $use_neutron {

    $openstack_network_hash  = hiera_hash('openstack_network', { })
    $neutron_config          = hiera_hash('neutron_config')
    $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
    $enable_qos              = pick($neutron_advanced_config['neutron_qos'], false)

    $core_plugin             = 'neutron.plugins.ml2.plugin.Ml2Plugin'
    $default_service_plugins = [
      'neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',
      'neutron.services.metering.metering_plugin.MeteringPlugin',
    ]

    if $enable_qos {
      $service_plugins = concat($default_service_plugins, ['qos'])
    } else {
      $service_plugins = $default_service_plugins
    }

    $rabbit_hash      = hiera_hash('rabbit', {})
    $ceilometer_hash  = hiera_hash('ceilometer', {})
    $network_scheme   = hiera_hash('network_scheme', {})
    $neutron_hash     = hiera_hash('neutron', {})

    $verbose      = pick($openstack_network_hash['verbose'], hiera('verbose', true))
    $debug        = pick($openstack_network_hash['debug'], hiera('debug', true))
    # TODO(aschultz): LP#1499620 - neutron in UCA liberty fails to start with
    # syslog enabled.
    $use_syslog = $::os_package_type ? {
      'ubuntu' => false,
      default  => hiera('use_syslog', true)
    }
    $use_stderr   = hiera('use_stderr', false)
    $log_facility = hiera('syslog_log_facility_neutron', 'LOG_LOCAL4')

    prepare_network_config($network_scheme)
    $bind_host = get_network_role_property('neutron/api', 'ipaddr')

    $base_mac       = $neutron_config['L2']['base_mac']
    $amqp_hosts     = split(hiera('amqp_hosts', ''), ',')
    $amqp_user      = $rabbit_hash['user']
    $amqp_password  = $rabbit_hash['password']

    $kombu_compression = hiera('kombu_compression', '')

    $segmentation_type = try_get_value($neutron_config, 'L2/segmentation_type')

    $nets = $neutron_config['predefined_networks']

    if $segmentation_type == 'vlan' {
      $net_role_property    = 'neutron/private'
      $iface                = get_network_role_property($net_role_property, 'phys_dev')
      $mtu_for_virt_network = pick(get_transformation_property('mtu', $iface[0]), '1500')
      $overlay_net_mtu      = $mtu_for_virt_network
    } else {
      $net_role_property = 'neutron/mesh'
      $iface             = get_network_role_property($net_role_property, 'phys_dev')
      $physical_net_mtu  = pick(get_transformation_property('mtu', $iface[0]), '1500')

      if $segmentation_type == 'gre' {
        $mtu_offset = '42'
      } else {
      # vxlan is the default segmentation type for non-vlan cases
        $mtu_offset = '50'
      }

      if $physical_net_mtu {
        $overlay_net_mtu = $physical_net_mtu - $mtu_offset
      } else {
        $overlay_net_mtu = '1500' - $mtu_offset
      }

    }

    $default_log_levels  = hiera_hash('default_log_levels')

    class { '::neutron' :
      verbose                 => $verbose,
      debug                   => $debug,
      use_syslog              => $use_syslog,
      use_stderr              => $use_stderr,
      lock_path               => '/var/lib/neutron/lock',
      log_facility            => $log_facility,
      bind_host               => $bind_host,
      base_mac                => $base_mac,
      core_plugin             => $core_plugin,
      service_plugins         => $service_plugins,
      allow_overlapping_ips   => true,
      mac_generation_retries  => '32',
      dhcp_lease_duration     => '600',
      dhcp_agents_per_network => '2',
      report_interval         => $neutron_hash['neutron_report_interval'],
      rabbit_user             => $amqp_user,
      rabbit_hosts            => $amqp_hosts,
      rabbit_password         => $amqp_password,
      kombu_reconnect_delay   => '5.0',
      network_device_mtu      => $overlay_net_mtu,
      advertise_mtu           => true,
    }

    # TODO (iberezovskiy): remove this workaround in N when neutron module
    # will be switched to puppet-oslo usage for rabbit configuration
    if $kombu_compression in ['gzip','bz2'] {
      if !defined(Oslo::Messaging_rabbit['neutron_config']) and !defined(Neutron_config['oslo_messaging_rabbit/kombu_compression']) {
        neutron_config { 'oslo_messaging_rabbit/kombu_compression': value => $kombu_compression; }
      } else {
        Neutron_config<| title == 'oslo_messaging_rabbit/kombu_compression' |> { value => $kombu_compression }
      }
    }

    if $default_log_levels {
      neutron_config {
        'DEFAULT/default_log_levels' :
          value => join(sort(join_keys_to_values($default_log_levels, '=')), ',');
      }
    } else {
      neutron_config { 'DEFAULT/default_log_levels' : ensure => absent; }
    }

    if $use_syslog {
      neutron_config { 'DEFAULT/use_syslog_rfc_format': value => true; }
    }

    neutron_config {
      'DEFAULT/notification_driver': value => $ceilometer_hash['notification_driver'];
    }

  }

  ### SYSCTL ###

  # All nodes with network functions should have net forwarding.
  # Its a requirement for network namespaces to function.
  sysctl::value { 'net.ipv4.ip_forward': value => '1' }

  # All nodes with network functions should have these thresholds
  # to avoid "Neighbour table overflow" problem
  sysctl::value { 'net.ipv4.neigh.default.gc_thresh1': value => '4096' }
  sysctl::value { 'net.ipv4.neigh.default.gc_thresh2': value => '8192' }
  sysctl::value { 'net.ipv4.neigh.default.gc_thresh3': value => '16384' }

  Sysctl::Value <| |> -> Nova_config <||>
  Sysctl::Value <| |> -> Neutron_config <||>

}
