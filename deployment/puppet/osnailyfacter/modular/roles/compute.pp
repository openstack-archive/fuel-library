notice('MODULAR: compute.pp')

$network_scheme = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

# Pulling hiera
$compute_hash                   = hiera_hash('compute', {})
$node_name                      = hiera('node_name')
$public_int                     = hiera('public_int', undef)
$public_vip                     = hiera('public_vip')
$management_vip                 = hiera('management_vip')
$database_vip                   = hiera('database_vip')
$service_endpoint               = hiera('service_endpoint')
$primary_controller             = hiera('primary_controller')
$use_neutron                    = hiera('use_neutron', false)
$sahara_hash                    = hiera('sahara', {})
$murano_hash                    = hiera('murano', {})
$mp_hash                        = hiera('mp')
$verbose                        = pick($compute_hash['verbose'], true)
$debug                          = pick($compute_hash['debug'], hiera('debug', true))
$use_monit                      = false
$auto_assign_floating_ip        = hiera('auto_assign_floating_ip', false)
$nodes_hash                     = hiera('nodes', {})
$storage_hash                   = hiera_hash('storage_hash', {})
$vcenter_hash                   = hiera('vcenter', {})
$nova_hash                      = hiera_hash('nova_hash', {})
$nova_custom_hash               = hiera_hash('nova_custom_hash', {})
$rabbit_hash                    = hiera_hash('rabbit_hash', {})
$glance_hash                    = hiera_hash('glance_hash', {})
$keystone_hash                  = hiera_hash('keystone_hash', {})
$swift_hash                     = hiera_hash('swift_hash', {})
$cinder_hash                    = hiera_hash('cinder_hash', {})
$ceilometer_hash                = hiera_hash('ceilometer_hash',{})
$access_hash                    = hiera('access', {})
$swift_proxies                  = hiera('swift_proxies')
$swift_master_role              = hiera('swift_master_role', 'primary-controller')
$neutron_mellanox               = hiera('neutron_mellanox', false)
$syslog_hash                    = hiera('syslog', {})
$base_syslog_hash               = hiera('base_syslog', {})
$use_syslog                     = hiera('use_syslog', true)
$use_stderr                     = hiera('use_stderr', false)
$syslog_log_facility_glance     = hiera('syslog_log_facility_glance', 'LOG_LOCAL2')
$syslog_log_facility_cinder     = hiera('syslog_log_facility_cinder', 'LOG_LOCAL3')
$syslog_log_facility_neutron    = hiera('syslog_log_facility_neutron', 'LOG_LOCAL4')
$syslog_log_facility_nova       = hiera('syslog_log_facility_nova','LOG_LOCAL6')
$syslog_log_facility_keystone   = hiera('syslog_log_facility_keystone', 'LOG_LOCAL7')
$syslog_log_facility_murano     = hiera('syslog_log_facility_murano', 'LOG_LOCAL0')
$syslog_log_facility_sahara     = hiera('syslog_log_facility_sahara','LOG_LOCAL0')
$nova_rate_limits               = hiera('nova_rate_limits')
$nova_report_interval           = hiera('nova_report_interval')
$nova_service_down_time         = hiera('nova_service_down_time')
$glance_api_servers             = hiera('glance_api_servers', "${management_vip}:9292")
$config_drive_format            = 'vfat'

$public_ssl_hash                = hiera('public_ssl')
$vncproxy_host = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}

$db_host                        = pick($nova_hash['db_host'], $database_vip)

$block_device_allocate_retries          = hiera('block_device_allocate_retries', 300)
$block_device_allocate_retries_interval = hiera('block_device_allocate_retries_interval', 3)

# TODO: openstack_version is confusing, there's such string var in hiera and hardcoded hash
$hiera_openstack_version = hiera('openstack_version')
$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

$queue_provider = hiera('queue_provider', 'rabbitmq')

# Do the stuff
if $neutron_mellanox {
  $mellanox_mode = $neutron_mellanox['plugin']
} else {
  $mellanox_mode = 'disabled'
}

if $use_neutron {
  $novanetwork_params        = {}
  $network_provider          = 'neutron'
  $neutron_config            = hiera_hash('quantum_settings')
  $neutron_db_password       = $neutron_config['database']['passwd']
  $neutron_user_password     = $neutron_config['keystone']['admin_password']
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $base_mac                  = $neutron_config['L2']['base_mac']
} else {
  $network_provider   = 'nova'
  $floating_ips_range = hiera('floating_network_range')
  $neutron_config     = {}
  $novanetwork_params = hiera('novanetwork_parameters')
}

if $primary_controller {
  if ($mellanox_mode == 'ethernet') {
    $test_vm_pkg = 'cirros-testvm-mellanox'
  } else {
    $test_vm_pkg = 'cirros-testvm'
  }
  package { 'cirros-testvm' :
    ensure => 'installed',
    name   => $test_vm_pkg,
  }
}

if !$rabbit_hash['user'] {
  $rabbit_hash['user'] = 'nova'
}

$floating_hash = {}

##CALCULATED PARAMETERS

##TODO: simply parse nodes array
$memcache_nodes   = get_nodes_hash_by_roles(hiera('network_metadata'), hiera('memcache_roles'))
$memcache_ipaddrs = ipsort(values(get_node_to_ipaddr_map_by_network_role($memcache_nodes,'mgmt/memcache')))
$roles            = $network_metadata['nodes'][$node_name]['node_roles']
$mountpoints      = filter_hash($mp_hash,'point')

# SQLAlchemy backend configuration
$max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
$max_overflow = min($::processorcount * 5 + 0, 60 + 0)
$max_retries = '-1'
$idle_timeout = '3600'

if ($storage_hash['volumes_lvm']) {
  nova_config { 'keymgr/fixed_key':
    value => $cinder_hash[fixed_key];
  }
}

# Determine who should get the volume service

if (member($roles, 'cinder') and $storage_hash['volumes_lvm']) {
  $manage_volumes = 'iscsi'
} elsif (member($roles, 'cinder') and $storage_hash['volumes_vmdk']) {
  $manage_volumes = 'vmdk'
} elsif ($storage_hash['volumes_ceph']) {
  $manage_volumes = 'ceph'
} else {
  $manage_volumes = false
}

#Determine who should be the default backend

if ($storage_hash['images_ceph']) {
  $glance_backend = 'ceph'
  $glance_known_stores = [ 'glance.store.rbd.Store', 'glance.store.http.Store' ]
} elsif ($storage_hash['images_vcenter']) {
  $glance_backend = 'vmware'
  $glance_known_stores = [ 'glance.store.vmware_datastore.Store', 'glance.store.http.Store' ]
} else {
  $glance_backend = 'swift'
  $glance_known_stores = [ 'glance.store.swift.Store', 'glance.store.http.Store' ]
}

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $use_swift = true
} else {
  $use_swift = false
}

# NOTE(bogdando) for controller nodes running Corosync with Pacemaker
#   we delegate all of the monitor functions to RA instead of monit.
if member($roles, 'controller') or member($roles, 'primary-controller') {
  $use_monit_real = false
} else {
  $use_monit_real = $use_monit
}

if $use_monit_real {
  # Configure service names for monit watchdogs and 'service' system path
  # FIXME(bogdando) replace service_path to systemd, once supported
  include nova::params
  include cinder::params
  include neutron::params
  $nova_compute_name   = $::nova::params::compute_service_name
  $nova_api_name       = $::nova::params::api_service_name
  $nova_network_name   = $::nova::params::network_service_name
  $cinder_volume_name  = $::cinder::params::volume_service
  $ovs_vswitchd_name   = $::l23network::params::ovs_service_name
  case $::osfamily {
    'RedHat' : {
      $service_path   = '/sbin/service'
    }
    'Debian' : {
      $service_path    = '/usr/sbin/service'
    }
    default  : {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }
}

#HARDCODED PARAMETERS
if hiera('use_vcenter', false) {
  $multi_host = false
} else {
  $multi_host = true
}

$mirror_type = 'external'
Exec { logoutput => true }

include osnailyfacter::test_compute

if ($::mellanox_mode == 'ethernet') {
  $neutron_private_net = pick($neutron_config['default_private_net'], 'net04')
  $physnet = $neutron_config['predefined_networks'][$neutron_private_net]['L2']['physnet']
  class { 'mellanox_openstack::compute':
    physnet => $physnet,
    physifc => $neutron_mellanox['physical_port'],
  }
}

# NOTE(bogdando) deploy compute node with disabled nova-compute
#   service #LP1398817. The orchestration will start and enable it back
#   after the deployment is done.
# FIXME(bogdando) This should be changed once the host aggregates implemented, bp disable-new-computes
class { 'openstack::compute':
  enabled                     => false,
  public_interface            => $public_int ? { undef=>'', default=>$public_int},
  private_interface           => $use_neutron ? { true=>false, default=>hiera('private_int', undef)},
  internal_address            => get_network_role_property('nova/api', 'ipaddr'),
  libvirt_type                => hiera('libvirt_type', undef),
  fixed_range                 => $use_neutron ? { true=>false, default=>hiera('fixed_network_range', undef)},
  network_manager             => hiera('network_manager', undef),
  network_config              => hiera('network_config', {}),
  multi_host                  => $multi_host,
  queue_provider              => $queue_provider,
  amqp_hosts                  => hiera('amqp_hosts',''),
  amqp_user                   => $rabbit_hash['user'],
  amqp_password               => $rabbit_hash['password'],
  rabbit_ha_queues            => $rabbit_ha_queues,
  auto_assign_floating_ip     => $auto_assign_floating_ip,
  glance_api_servers          => $glance_api_servers,
  vncproxy_host               => $vncproxy_host,
  vncserver_listen            => '0.0.0.0',
  migration_support           => true,
  debug                       => $debug,
  verbose                     => $verbose,
  use_stderr                  => $use_stderr,
  cinder_volume_group         => 'cinder',
  vnc_enabled                 => true,
  manage_volumes              => $manage_volumes,
  nova_user_password          => $nova_hash[user_password],
  nova_hash                   => $nova_hash,
  cache_server_ip             => $memcache_ipaddrs,
  service_endpoint            => $service_endpoint,
  cinder                      => true,
  cinder_iscsi_bind_addr      => get_network_role_property('cinder/iscsi', 'ipaddr'),
  cinder_user_password        => $cinder_hash[user_password],
  cinder_db_password          => $cinder_hash[db_password],
  ceilometer                  => $ceilometer_hash[enabled],
  ceilometer_metering_secret  => $ceilometer_hash[metering_secret],
  ceilometer_user_password    => $ceilometer_hash[user_password],
  db_host                     => $db_host,
  network_provider            => $network_provider,
  neutron_user_password       => $use_neutron ? { true=>$neutron_config['keystone']['admin_password'], default=>undef},
  base_mac                    => $base_mac,

  use_syslog                  => $use_syslog,
  syslog_log_facility         => $syslog_log_facility_nova,
  syslog_log_facility_neutron => $syslog_log_facility_neutron,
  nova_rate_limits            => $nova_rate_limits,
  nova_report_interval        => $nova_report_interval,
  nova_service_down_time      => $nova_service_down_time,
  state_path                  => $nova_hash[state_path],
  neutron_settings            => $neutron_config,
  storage_hash                => $storage_hash,
  config_drive_format         => $config_drive_format,
}

# Required for fping API extension, see LP#1486404
ensure_packages('fping')

$nova_config_hash = {
  'DEFAULT/resume_guests_state_on_host_boot'       => { value => hiera('resume_guests_state_on_host_boot', 'False') },
  'DEFAULT/use_cow_images'                         => { value => hiera('use_cow_images', 'True') },
  'DEFAULT/block_device_allocate_retries'          => { value => $block_device_allocate_retries },
  'DEFAULT/block_device_allocate_retries_interval' => { value => $block_device_allocate_retries_interval },
  'libvirt/libvirt_inject_key'                     => { value => 'true' },
  'libvirt/libvirt_inject_password'                => { value => 'true' },
}

$nova_complete_hash = merge($nova_config_hash, $nova_custom_hash)

class {'nova::config':
  nova_config => $nova_complete_hash,
}

# Configure monit watchdogs
# FIXME(bogdando) replace service_path and action to systemd, once supported
if $use_monit_real {
  monit::process { $nova_compute_name :
    ensure        => running,
    matching      => '/usr/bin/python /usr/bin/nova-compute',
    start_command => "${service_path} ${nova_compute_name} restart",
    stop_command  => "${service_path} ${nova_compute_name} stop",
    pidfile       => false,
  }
  if $use_neutron {
    monit::process { $ovs_vswitchd_name :
      ensure        => running,
      start_command => "${service_path} ${ovs_vswitchd_name} restart",
      stop_command  => "${service_path} ${ovs_vswitchd_name} stop",
      pidfile       => '/var/run/openvswitch/ovs-vswitchd.pid',
    }
  } else {
    monit::process { $nova_network_name :
      ensure        => running,
      matching      => '/usr/bin/python /usr/bin/nova-network',
      start_command => "${service_path} ${nova_network_name} restart",
      stop_command  => "${service_path} ${nova_network_name} stop",
      pidfile       => false,
    }
    monit::process { $nova_api_name :
      ensure        => running,
      matching      => '/usr/bin/python /usr/bin/nova-api',
      start_command => "${service_path} ${nova_api_name} restart",
      stop_command  => "${service_path} ${nova_api_name} stop",
      pidfile       => false,
    }
  }
}

########################################################################


# vim: set ts=2 sw=2 et :
