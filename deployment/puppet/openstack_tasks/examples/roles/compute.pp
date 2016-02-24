notice('MODULAR: compute.pp')

$network_scheme = hiera_hash('network_scheme', {})
$override_configuration = hiera_hash('configuration', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

# override nova options
override_resources { 'nova_config':
  data => $override_configuration['nova_config']
}

# override nova-api options
override_resources { 'nova_paste_api_ini':
  data => $override_configuration['nova_paste_api_ini']
}

Override_resources <||> ~> Service <| tag == 'nova-service' |>

# Pulling hiera
$compute_hash                   = hiera_hash('compute', {})
$public_int                     = hiera('public_int', undef)
$public_vip                     = hiera('public_vip')
$management_vip                 = hiera('management_vip')
$database_vip                   = hiera('database_vip')
$service_endpoint               = hiera('service_endpoint')
$sahara_hash                    = hiera_hash('sahara', {})
$murano_hash                    = hiera_hash('murano', {})
$mp_hash                        = hiera('mp')
$verbose                        = pick($compute_hash['verbose'], true)
$debug                          = pick($compute_hash['debug'], hiera('debug', true))
$storage_hash                   = hiera_hash('storage', {})
$nova_hash                      = hiera_hash('nova', {})
$nova_custom_hash               = hiera_hash('nova_custom', {})
$rabbit_hash                    = hiera_hash('rabbit', {})
$keystone_hash                  = hiera_hash('keystone', {})
$cinder_hash                    = hiera_hash('cinder', {})
$ceilometer_hash                = hiera_hash('ceilometer', {})
$access_hash                    = hiera_hash('access', {})
$neutron_mellanox               = hiera('neutron_mellanox', false)
$syslog_hash                    = hiera_hash('syslog', {})
$base_syslog_hash               = hiera_hash('base_syslog', {})
$use_syslog                     = hiera('use_syslog', true)
$use_stderr                     = hiera('use_stderr', false)
$syslog_log_facility            = hiera('syslog_log_facility_nova','LOG_LOCAL6')
$config_drive_format            = 'vfat'
$public_ssl_hash                = hiera_hash('public_ssl')
$ssl_hash                       = hiera_hash('use_ssl', {})
$node_hash                      = hiera_hash('node', {})
$use_huge_pages                 = pick($node_hash['nova_hugepages_enabled'], false)

$dpdk_config                    = hiera_hash('dpdk', {})
$enable_dpdk                    = pick($dpdk_config['enabled'], false)
if $enable_dpdk {
  # LP 1533876
  $network_device_mtu = false
} else {
  $network_device_mtu = 65000
}


$glance_protocol                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
$glance_endpoint                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [hiera('glance_endpoint', $management_vip)])
$glance_internal_ssl            = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'usage', false)
if $glance_internal_ssl {
  $glance_api_servers = "${glance_protocol}://${glance_endpoint}:9292"
} else {
  $glance_api_servers = hiera('glance_api_servers', "${management_vip}:9292")
}

$vncproxy_protocol                      = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'protocol', [$nova_hash['vncproxy_protocol'], 'http'])
$vncproxy_host                          = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'hostname', [$public_vip])

$block_device_allocate_retries          = hiera('block_device_allocate_retries', 300)
$block_device_allocate_retries_interval = hiera('block_device_allocate_retries_interval', 3)

$rpc_backend = hiera('queue_provider', 'rabbit')

# FIXME(xarses) Should be removed after
# https://bugs.launchpad.net/fuel/+bug/1555284
if $rpc_backend == 'rabbitmq' {
  $rpc_backend_real = 'rabbit'
} else {
  $rpc_backend_real = $rpc_backend
}

# Do the stuff
if $neutron_mellanox {
  $mellanox_mode = $neutron_mellanox['plugin']
} else {
  $mellanox_mode = 'disabled'
}

include ::osnailyfacter::test_compute

if ($::mellanox_mode == 'ethernet') {
  $neutron_config      = hiera_hash('quantum_settings')
  $neutron_private_net = pick($neutron_config['default_private_net'], 'net04')
  $physnet             = $neutron_config['predefined_networks'][$neutron_private_net]['L2']['physnet']
  class { '::mellanox_openstack::compute':
    physnet => $physnet,
    physifc => $neutron_mellanox['physical_port'],
  }
}

$floating_hash = {}

##CALCULATED PARAMETERS

# TODO(xarses): Wait Nova compute uses memcache?
$memcached_server = hiera('memcached_addresses')
$memcached_port   = hiera('memcache_server_port', '11211')

# TODO(xarses): We need to validate this is needed
if ($storage_hash['volumes_lvm']) {
  nova_config { 'keymgr/fixed_key':
    value => $cinder_hash[fixed_key];
  }
}



# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $use_swift = true
} else {
  $use_swift = false
}

# Get reserved host memory straight value if we've ceph neighbor
$r_hostmem = roles_include(['ceph-osd']) ? {
  true  => min(max(floor($::memorysize_mb*0.2), 512), 1536),
  false => undef,
}

$mirror_type = 'external'
Exec { logoutput => true }

$oc_nova_hash = merge({ 'reserved_host_memory' => $r_hostmem }, $nova_hash)

# NOTE(bogdando) deploy compute node with disabled nova-compute
#   service #LP1398817. The orchestration will start and enable it back
#   after the deployment is done.
# FIXME(bogdando) This should be changed once the host aggregates implemented, bp disable-new-computes
class { '::openstack::compute':
  enabled                     => false,
  internal_address            => get_network_role_property('nova/api', 'ipaddr'),
  libvirt_type                => hiera('libvirt_type', undef),
  rpc_backend                 => $rpc_backend_real,
  amqp_hosts                  => hiera('amqp_hosts',''),
  amqp_user                   => pick($rabbit_hash['user'], 'nova'),
  amqp_password               => $rabbit_hash['password'],
  glance_api_servers          => $glance_api_servers,
  vncproxy_protocol           => $vncproxy_protocol,
  vncproxy_host               => $vncproxy_host,
  debug                       => $debug,
  verbose                     => $verbose,
  use_stderr                  => $use_stderr,
  nova_hash                   => $oc_nova_hash,
  cache_server_ip             => $memcached_server,
  cache_server_port           => $memcached_port,
  notification_driver         => $ceilometer_hash['notification_driver'],
  pci_passthrough             => nic_whitelist_to_json(get_nic_passthrough_whitelist('sriov')),
  network_device_mtu          => $network_device_mtu,
  use_syslog                  => $use_syslog,
  syslog_log_facility         => $syslog_log_facility,
  nova_report_interval        => $nova_hash['nova_report_interval'],
  nova_service_down_time      => $nova_hash['nova_service_down_time'],
  state_path                  => $nova_hash[state_path],
  storage_hash                => $storage_hash,
  config_drive_format         => $config_drive_format,
  use_huge_pages              => $use_huge_pages,
  vcpu_pin_set                => $nova_hash['cpu_pinning'],
}

# Required for fping API extension, see LP#1486404
ensure_packages('fping')

$nova_config_hash = {
  'DEFAULT/resume_guests_state_on_host_boot'       => { value => hiera('resume_guests_state_on_host_boot', 'False') },
  'DEFAULT/use_cow_images'                         => { value => hiera('use_cow_images', 'True') },
  'DEFAULT/block_device_allocate_retries'          => { value => $block_device_allocate_retries },
  'DEFAULT/block_device_allocate_retries_interval' => { value => $block_device_allocate_retries_interval },
  'libvirt/libvirt_inject_key'                     => { value => true },
  'libvirt/libvirt_inject_password'                => { value => true },
}

$nova_complete_hash = merge($nova_config_hash, $nova_custom_hash)

class {'::nova::config':
  nova_config => $nova_complete_hash,
}

########################################################################


# vim: set ts=2 sw=2 et :
