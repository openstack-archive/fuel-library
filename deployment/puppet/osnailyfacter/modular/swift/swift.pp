notice('MODULAR: swift.pp')

$swift_hash             = hiera('swift_hash')
$swift_master_role      = hiera('swift_master_role', 'primary-controller')
$swift_nodes            = hiera('swift_nodes', {})
$swift_proxies          = hiera('swift_proxies', {})
$is_primary_swift_proxy = hiera('is_primary_swift_proxy', false)

$proxy_port          = hiera('proxy_port', '8080')
$network_scheme      = hiera_hash('network_scheme')
$network_metadata    = hiera_hash('network_metadata')
$storage_hash        = hiera('storage_hash')
$mp_hash             = hiera('mp')
$management_vip      = hiera('management_vip')
$public_vip          = hiera('public_vip')
$debug               = hiera('debug', false)
$verbose             = hiera('verbose')
$node                = hiera('node')
$ring_min_part_hours = hiera('swift_ring_min_part_hours', 1)

prepare_network_config($network_scheme)

$storage_address     = get_network_role_property('swift/replication', 'ipaddr')

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  if !(hiera('swift_partition', false)) {
    $swift_partition = '/var/lib/glance/node'
  }
  $master_swift_proxy_nodes      = get_nodes_hash_by_roles($network_metadata, [$swift_master_role])
  $master_swift_proxy_node_names = keys($master_swift_proxy_nodes)
  $master_swift_proxy_ip = $master_swift_proxy_nodes[$master_swift_proxy_node_names[0]]['network_roles']['swift/api']

  class { 'openstack::swift::storage_node':
    storage_type          => false,
    loopback_size         => '5243780',
    storage_mnt_base_dir  => $swift_partition,
    storage_devices       => filter_hash($mp_hash,'point'),
    swift_zone            => $master_swift_proxy_nodes[$master_swift_proxy_node_names[0]]['swift_zone'],
    swift_local_net_ip    => $storage_address,
    master_swift_proxy_ip => $master_swift_proxy_ip,
    sync_rings            => ! $is_primary_swift_proxy,
    debug                 => $debug,
    verbose               => $verbose,
    log_facility          => 'LOG_SYSLOG',
  }
  if $is_primary_swift_proxy {
    ring_devices {'all':
      storages => $swift_nodes,
      require  => Class['swift'],
    }
  }

  if has_key($swift_hash, 'resize_value') {
    $resize_value = $swift_hash['resize_value']
  } else {
    $resize_value = 2
  }

  $ring_part_power = calc_ring_part_power($swift_nodes,$resize_value)
  $sto_net = get_network_role_property('swift/replication', 'network')
  $man_net = get_network_role_property('swift/api', 'network')

  class { 'openstack::swift::proxy':
    swift_user_password     => $swift_hash['user_password'],
    swift_proxies           => get_network_role_to_ipaddr_map($swift_proxies, 'swift/public'),
    ring_part_power         => $ring_part_power,
    primary_proxy           => $is_primary_swift_proxy,
    controller_node_address => $management_vip,
    swift_local_net_ip      => $storage_address,
    master_swift_proxy_ip   => $master_swift_proxy_ip,
    proxy_port              => $proxy_port,
    debug                   => $debug,
    verbose                 => $verbose,
    log_facility            => 'LOG_SYSLOG',
    ceilometer              => hiera('use_ceilometer',false),
    ring_min_part_hours     => $ring_min_part_hours,
  } ->

  class { 'openstack::swift::status':
    endpoint    => "http://${storage_address}:${proxy_port}",
    vip         => $management_vip,
    only_from   => "127.0.0.1 240.0.0.2 ${sto_net} ${man_net}",
    con_timeout => 5
  }

  class { 'swift::keystone::auth':
    password         => $swift_hash['user_password'],
    public_address   => $public_vip,
    internal_address => $management_vip,
    admin_address    => $management_vip,
  }

}

# 'ceilometer' class is being declared inside openstack::ceilometer class
# which is declared inside openstack::controller class in the other task.
# So we need a stub here for dependency from swift::proxy::ceilometer
class ceilometer {}
include ceilometer

