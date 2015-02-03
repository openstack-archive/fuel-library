$swift_hash      = hiera('swift_hash')
$storage_hash    = hiera('storage_hash')
$mp_hash         = hiera('mp')
$management_vip  = hiera('management_vip')
$debug           = hiera('debug', false)
$verbose         = hiera('verbose')
$storage_address = hiera('storage_address')
$node            = hiera('node')

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  if !(hiera('swift_partition', false)) {
    $swift_partition = '/var/lib/glance/node'
  }
  $master_swift_proxy_nodes = filter_nodes(hiera('nodes_hash'),'role','primary-controller')
  $master_swift_proxy_ip    = $master_swift_proxy_nodes[0]['storage_address']
  if (hiera('primary_controller')) {
    $primary_proxy = true
  } else {
    $primary_proxy = false
  }

  class { 'openstack::swift::storage_node':
    storage_type          => false,
    loopback_size         => '5243780',
    storage_mnt_base_dir  => $swift_partition,
    storage_devices       => filter_hash($mp_hash,'point'),
    swift_zone            => $node[0]['swift_zone'],
    swift_local_net_ip    => $storage_address,
    master_swift_proxy_ip => $master_swift_proxy_ip,
    sync_rings            => ! $primary_proxy,
    debug                 => $debug,
    verbose               => $verbose,
    log_facility          => 'LOG_SYSLOG',
  }
  if $primary_proxy {
    ring_devices {'all':
      storages => $controllers,
      require  => Class['swift'],
    }
  }

  if !$swift_hash['resize_value']
  {
    $swift_hash['resize_value'] = 2
  }

  $ring_part_power = calc_ring_part_power($controllers,$swift_hash['resize_value'])

  class { 'openstack::swift::proxy':
    swift_user_password     => $swift_hash[user_password],
    swift_proxies           => $controller_internal_addresses,
    ring_part_power         => $ring_part_power,
    primary_proxy           => $primary_proxy,
    controller_node_address => $management_vip,
    swift_local_net_ip      => $storage_address,
    master_swift_proxy_ip   => $master_swift_proxy_ip,
    debug                   => $debug,
    verbose                 => $verbose,
    log_facility            => 'LOG_SYSLOG',
  }

  class { 'swift::keystone::auth':
    password         => $swift_hash[user_password],
    public_address   => hiera('public_vip'),
    internal_address => $management_vip,
    admin_address    => $management_vip,
  }
}
