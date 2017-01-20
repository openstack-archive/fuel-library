class openstack_tasks::openstack_network::common_config {

  notice('MODULAR: openstack_network/common_config.pp')

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

  $neutron_config_l3   = pick($neutron_config['l3'], {})
  $dhcp_lease_duration = pick($neutron_config_l3['dhcp_lease_duration'], '600')

  $rabbit_hash      = hiera_hash('rabbit', {})
  $ceilometer_hash  = hiera_hash('ceilometer', {})
  $network_scheme   = hiera_hash('network_scheme', {})

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

  $base_mac        = $neutron_config['L2']['base_mac']

  $transport_url = hiera('transport_url','rabbit://guest:password@127.0.0.1:5672/')

  $kombu_compression = hiera('kombu_compression', $::os_service_default)

  $segmentation_type = dig44($neutron_config, ['L2', 'segmentation_type'])

  $nets = $neutron_config['predefined_networks']

  if $segmentation_type == 'vlan' {
    $net_role_property = 'neutron/private'
  } else {
    $net_role_property = 'neutron/mesh'
  }

  $iface = get_network_role_property($net_role_property, 'phys_dev')

  if $iface {
    $physical_net_mtu = pick(get_transformation_property('mtu', $iface[0]), '1500')
  } else {
    $physical_net_mtu = '1500'
  }

  $default_log_levels = hiera_hash('default_log_levels')

  # manually add line to neutron_sudoers in case of UCA packages
  # because UCA doesn't have such line
  if $::os_package_type == 'ubuntu' {
    file_line { 'root_helper_daemon':
      line  => 'neutron ALL = (root) NOPASSWD: /usr/bin/neutron-rootwrap-daemon /etc/neutron/rootwrap.conf',
      path  => '/etc/sudoers.d/neutron_sudoers',
      match => '^neutron ALL = (root) NOPASSWD: /usr/bin/neutron-rootwrap-daemon',
    }
    Package['neutron'] -> File_line[ 'root_helper_daemon'] -> Neutron_config<||>
  }

  class { '::neutron' :
    default_transport_url              => $transport_url,
    lock_path                          => '/var/lib/neutron/lock',
    bind_host                          => $bind_host,
    base_mac                           => $base_mac,
    core_plugin                        => $core_plugin,
    service_plugins                    => $service_plugins,
    allow_overlapping_ips              => true,
    dhcp_lease_duration                => $dhcp_lease_duration,
    dhcp_agents_per_network            => '2',
    report_interval                    => $neutron_config['neutron_report_interval'],
    rabbit_heartbeat_timeout_threshold => 0,
    kombu_compression                  => $kombu_compression,
    global_physnet_mtu                 => $physical_net_mtu,
    notification_driver                => $ceilometer_hash['notification_driver'],
    manage_logging                     => false,
    root_helper_daemon                 => 'sudo neutron-rootwrap-daemon /etc/neutron/rootwrap.conf'
  }

  class { '::neutron::logging':
    debug               => $debug,
    use_syslog          => $use_syslog,
    use_stderr          => $use_stderr,
    syslog_log_facility => $log_facility,
    default_log_levels  => $default_log_levels,
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
