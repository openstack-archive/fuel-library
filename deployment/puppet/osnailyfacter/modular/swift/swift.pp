notice('MODULAR: swift.pp')

$swift_hash          = hiera('swift_hash')
$proxy_port          = hiera('proxy_port', '8080')
$network_scheme      = hiera('network_scheme', {})
$storage_hash        = hiera('storage_hash')
$mp_hash             = hiera('mp')
$management_vip      = hiera('management_vip')
$debug               = hiera('debug', false)
$verbose             = hiera('verbose')
$storage_address     = hiera('storage_address')
$node                = hiera('node')
$controllers         = hiera('controllers')
$ring_min_part_hours = hiera('swift_ring_min_part_hours', 1)

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
  $sto_net = $network_scheme['endpoints'][$network_scheme['roles']['storage']]['IP']
  $man_net = $network_scheme['endpoints'][$network_scheme['roles']['management']]['IP']

  class { 'openstack::swift::proxy':
    swift_user_password     => $swift_hash[user_password],
    swift_proxies           => hiera('controller_internal_addresses'),
    ring_part_power         => $ring_part_power,
    primary_proxy           => $primary_proxy,
    controller_node_address => $management_vip,
    swift_local_net_ip      => $storage_address,
    master_swift_proxy_ip   => $master_swift_proxy_ip,
    proxy_port              => $proxy_port,
    debug                   => $debug,
    verbose                 => $verbose,
    log_facility            => 'LOG_SYSLOG',
    ceilometer              => hiera('use_ceilometer'),
    ring_min_part_hours     => $ring_min_part_hours,
  } ->

  class { 'openstack::swift::status':
    endpoint    => "http://${storage_address}:${proxy_port}",
    vip         => $management_vip,
    only_from   => "127.0.0.1 240.0.0.2 ${sto_net} ${man_net}",
    con_timeout => 5
  }

  class { 'swift::keystone::auth':
    password         => $swift_hash[user_password],
    public_address   => hiera('public_vip'),
    region           => hira('region', 'RegionOne'),
    internal_address => $management_vip,
    admin_address    => $management_vip,
  }

}

# 'ceilometer' class is being declared inside openstack::ceilometer class
# which is declared inside openstack::controller class in the other task.
# So we need a stub here for dependency from swift::proxy::ceilometer
class ceilometer {}
include ceilometer

