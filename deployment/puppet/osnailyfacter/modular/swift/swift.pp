notice('MODULAR: swift.pp')

$network_scheme   = hiera_hash('network_scheme')
$network_metadata = hiera_hash('network_metadata')
prepare_network_config($network_scheme)

$swift_hash              = hiera_hash('swift_hash')
$swift_master_role       = hiera('swift_master_role', 'primary-controller')
$swift_nodes             = hiera_hash('swift_nodes', {})
$swift_proxies_addr_list = values(get_node_to_ipaddr_map_by_network_role(hiera_hash('swift_proxies', {}), 'swift/api'))
# todo(sv) replace 'management' to mgmt/memcache
$memcaches_addr_list     = values(get_node_to_ipaddr_map_by_network_role(hiera_hash('swift_proxy_caches', {}), 'management'))
$is_primary_swift_proxy  = hiera('is_primary_swift_proxy', false)
$proxy_port              = hiera('proxy_port', '8080')
$storage_hash            = hiera_hash('storage_hash')
$mp_hash                 = hiera('mp')
$management_vip          = hiera('management_vip')
$public_vip              = hiera('public_vip')
$swift_api_ipaddr        = get_network_role_property('swift/api', 'ipaddr')
$swift_storage_ipaddr    = get_network_role_property('swift/replication', 'ipaddr')
$debug                   = hiera('debug', false)
$verbose                 = hiera('verbose', false)
$node                    = hiera('node')
$ring_min_part_hours     = hiera('swift_ring_min_part_hours', 1)
$deploy_swift_storage    = hiera('deploy_swift_storage', true)
$deploy_swift_proxy      = hiera('deploy_swift_proxy', true)
$create_keystone_auth    = pick($swift_hash['create_keystone_auth'], true)
#Keystone settings
$service_endpoint        = hiera('service_endpoint', $management_vip)
$keystone_endpoint       = hiera('keystone_endpoint', $service_endpoint)
$keystone_user           = pick($swift_hash['user'], 'swift')
$keystone_password       = pick($swift_hash['user_password'], 'passsword')
$keystone_tenant         = pick($swift_hash['tenant'], 'services')
$keystone_protocol       = pick($swift_hash['auth_protocol'], 'http')



# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $master_swift_proxy_nodes      = get_nodes_hash_by_roles($network_metadata, [$swift_master_role])
  $master_swift_proxy_nodes_list = values($master_swift_proxy_nodes)
  $master_swift_proxy_ip         = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/api'], '\/\d+$', '')
  $master_swift_replication_ip       = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/replication'], '\/\d+$', '')

  if ($deploy_swift_storage){
    class { 'openstack::swift::storage_node':
      storage_type          => false,
      loopback_size         => '5243780',
      storage_mnt_base_dir  => $swift_partition,
      storage_devices       => filter_hash($mp_hash,'point'),
      swift_zone            => $master_swift_proxy_nodes_list[0]['swift_zone'],
      swift_local_net_ip    => $swift_storage_ipaddr,
      master_swift_proxy_ip       => $master_swift_proxy_ip,
      master_swift_replication_ip => $master_swift_replication_ip,
      sync_rings            => ! $is_primary_swift_proxy,
      debug                 => $debug,
      verbose               => $verbose,
      log_facility          => 'LOG_SYSLOG',
    }
  }

  if $is_primary_swift_proxy {
    ring_devices {'all':
      storages => $swift_nodes,
      require  => Class['swift'],
    }
  }

  if ($deploy_swift_proxy){
    $resize_value = pick($swift_hash['resize_value'], 2)
    $ring_part_power = calc_ring_part_power($swift_nodes,$resize_value)
    $sto_net = get_network_role_property('swift/replication', 'network')
    $man_net = get_network_role_property('swift/api', 'network')

    class { 'openstack::swift::proxy':
      swift_user_password     => $swift_hash['user_password'],
      swift_proxies_cache     => $memcaches_addr_list,
      ring_part_power         => $ring_part_power,
      primary_proxy           => $is_primary_swift_proxy,
      swift_proxy_local_ipaddr       => $swift_api_ipaddr,
      swift_replication_local_ipaddr => $swift_storage_ipaddr,
      master_swift_proxy_ip          => $master_swift_proxy_ip,
      master_swift_replication_ip    => $master_swift_replication_ip,
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
      endpoint    => "http://${swift_api_ipaddr}:${proxy_port}",
      vip         => $management_vip,
      only_from   => "127.0.0.1 240.0.0.2 ${sto_net} ${man_net}",
      con_timeout => 5
    }

    if ($create_keystone_auth){
      class { 'swift::keystone::auth':
        password         => $swift_hash['user_password'],
        public_address   => $public_vip,
        internal_address => $management_vip,
        admin_address    => $management_vip,
      }
    }
  }
}

# 'ceilometer' class is being declared inside openstack::ceilometer class
# which is declared inside openstack::controller class in the other task.
# So we need a stub here for dependency from swift::proxy::ceilometer
class ceilometer {}
include ceilometer

