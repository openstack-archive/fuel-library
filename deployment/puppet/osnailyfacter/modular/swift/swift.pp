notice('MODULAR: swift.pp')

$swift_hash           = hiera_hash('swift_hash')
$swift_master_role    = hiera('swift_master_role', 'primary-controller')
$swift_nodes          = pick(hiera('swift_nodes', undef), hiera('controllers', undef))
$swift_proxies_cache  = pick(hiera('swift_proxies_cache', undef), hiera('controller_nodes', undef))
$primary_swift        = pick(hiera('primary_swift', undef), hiera('primary_controller', undef))
$proxy_port           = hiera('proxy_port', '8080')
$network_scheme       = hiera('network_scheme', {})
$storage_hash         = hiera('storage_hash')
$mp_hash              = hiera('mp')
$management_vip       = hiera('management_vip')
$debug                = hiera('debug', false)
$verbose              = hiera('verbose')
$storage_address      = hiera('storage_address')
$node                 = hiera('node')
$ring_min_part_hours  = hiera('swift_ring_min_part_hours', 1)
$deploy_swift_storage = hiera($swift_hash['deploy_swift_storage'], true)
$deploy_swift_proxy   = hiera($swift_hash['deploy_swift_proxy'], true)
#Keystone settings
$service_endpoint     = hiera('service_endpoint', $management_vip)
$keystone_endpoint    = hiera('keystone_endpoint', $service_endpoint)
$keystone_user        = pick($swift_hash['auth_name'], 'swift')
$keystone_password    = $swift_hash['user_password']
$keystone_tenant      = pick($swift_hash['tenant'], 'services')
$keystone_protocol    = pick($swift_hash['auth_protocol'], 'http')
$region               = hiera('region', 'RegionOne')

validate_string($keystone_password)

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $swift_partition          = hiera('swift_partition', '/var/lib/glance/node')
  $master_swift_proxy_nodes = filter_nodes(hiera('nodes_hash'),'role',$swift_master_role)
  $master_swift_proxy_ip    = $master_swift_proxy_nodes[0]['storage_address']
  if ($primary_swift) {
    $primary_proxy = true
  } else {
    $primary_proxy = false
  }
  if ($deploy_swift_storage){
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
  }
  if $primary_proxy {
    ring_devices {'all':
      storages => $swift_nodes,
      require  => Class['swift'],
    }
  }

  if $deploy_swift_proxy {
    $resize_value = pick($swift_hash['resize_value'], 2)

    $ring_part_power = calc_ring_part_power($swift_nodes,$resize_value)
    $sto_net = $network_scheme['endpoints'][$network_scheme['roles']['storage']]['IP']
    $man_net = $network_scheme['endpoints'][$network_scheme['roles']['management']]['IP']

    class { 'openstack::swift::proxy':
      swift_user_password     => $swift_hash['user_password'],
      swift_proxies_cache     => $swift_proxies_cache,
      ring_part_power         => $ring_part_power,
      primary_proxy           => $primary_proxy,
      swift_local_net_ip      => $storage_address,
      master_swift_proxy_ip   => $master_swift_proxy_ip,
      proxy_port              => $proxy_port,
      debug                   => $debug,
      verbose                 => $verbose,
      log_facility            => 'LOG_SYSLOG',
      ceilometer              => hiera('use_ceilometer',false),
      ring_min_part_hours     => $ring_min_part_hours,
      admin_user              => $keystone_user,
      admin_tenant_name       => $keystone_tenant,
      admin_password          => $keystone_password,
      auth_host               => $keystone_endpoint,
      auth_protocol           => $keystone_protocol,
    } ->

    class { 'openstack::swift::status':
      endpoint    => "http://${storage_address}:${proxy_port}",
      vip         => $management_vip,
      only_from   => "127.0.0.1 240.0.0.2 ${sto_net} ${man_net}",
      con_timeout => 5
    }

  }
}

# 'ceilometer' class is being declared inside openstack::ceilometer class
# which is declared inside openstack::controller class in the other task.
# So we need a stub here for dependency from swift::proxy::ceilometer
class ceilometer {}
include ceilometer

# Class[Swift::Proxy::Cache] requires Class[Memcached] if memcache_servers
# contains 127.0.0.1. But we're deploying memcached in another task. So we
# need to add this stub here.
class memcached {}
include memcached

