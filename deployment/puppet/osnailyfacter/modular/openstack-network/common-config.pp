notice('MODULAR: openstack-network/common-config.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {

  $openstack_network_hash = hiera_hash('openstack_network', { })
  $neutron_config         = hiera_hash('neutron_config')

  $core_plugin            = 'neutron.plugins.ml2.plugin.Ml2Plugin'
  $service_plugins        = [
    'neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',
    'neutron.services.metering.metering_plugin.MeteringPlugin',
  ]

  $rabbit_hash      = hiera_hash('rabbit_hash', { })
  $ceilometer_hash  = hiera_hash('ceilometer', { })
  $network_scheme   = hiera_hash('network_scheme', {})

  $verbose      = pick($openstack_network_hash['verbose'], hiera('verbose', true))
  $debug        = pick($openstack_network_hash['debug'], hiera('debug', true))
  $use_syslog   = hiera('use_syslog', true)
  $use_stderr   = hiera('use_stderr', false)
  $log_facility = hiera('syslog_log_facility_neutron', 'LOG_LOCAL4')

  prepare_network_config($network_scheme)
  $bind_host = get_network_role_property('neutron/api', 'ipaddr')

  $base_mac       = $neutron_config['L2']['base_mac']
  $use_ceilometer = $ceilometer_hash['enabled']
  $amqp_hosts     = split(hiera('amqp_hosts', ''), ',')
  $amqp_user      = $rabbit_hash['user']
  $amqp_password  = $rabbit_hash['password']

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

  class { 'neutron' :
    verbose                 => $verbose,
    debug                   => $debug,
    use_syslog              => $use_syslog,
    use_stderr              => $use_stderr,
    log_facility            => $log_facility,
    bind_host               => $bind_host,
    base_mac                => $base_mac,
    core_plugin             => $core_plugin,
    service_plugins         => $service_plugins,
    allow_overlapping_ips   => true,
    mac_generation_retries  => '32',
    dhcp_lease_duration     => '600',
    dhcp_agents_per_network => '2',
    report_interval         => '10',
    rabbit_user             => $amqp_user,
    rabbit_hosts            => $amqp_hosts,
    rabbit_password         => $amqp_password,
    network_device_mtu      => $overlay_net_mtu,
    advertise_mtu           => true,
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

  if $use_ceilometer {
    neutron_config { 'DEFAULT/notification_driver': value => 'messaging' }
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
