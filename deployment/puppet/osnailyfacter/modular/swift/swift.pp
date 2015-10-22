notice('MODULAR: swift.pp')

<<<<<<< HEAD
$network_scheme   = hiera_hash('network_scheme')
$network_metadata = hiera_hash('network_metadata')
prepare_network_config($network_scheme)
||||||| parent of 68ac4bb... Rework selective SSL support
$swift_hash                  = hiera_hash('swift_hash')
$swift_master_role           = hiera('swift_master_role', 'primary-controller')
$swift_nodes                 = pick(hiera('swift_nodes', undef), hiera('controllers', undef))
$swift_proxies_cache         = pick(hiera('swift_proxies_cache', undef), hiera('controller_nodes', undef))
$primary_swift               = pick(hiera('primary_swift', undef), hiera('primary_controller', undef))
$proxy_port                  = hiera('proxy_port', '8080')
$network_scheme              = hiera('network_scheme', {})
$storage_hash                = hiera('storage_hash')
$mp_hash                     = hiera('mp')
$management_vip              = hiera('management_vip')
$public_vip                  = hiera('public_vip')
$debug                       = pick($swift_hash['debug'], hiera('debug', false))
$verbose                     = pick($swift_hash['verbose'], hiera('verbose'))
$storage_address             = hiera('storage_address')
$node                        = hiera('node')
$ring_min_part_hours         = hiera('swift_ring_min_part_hours', 1)
$deploy_swift_storage        = hiera('deploy_swift_storage', true)
$deploy_swift_proxy          = hiera('deploy_swift_proxy', true)
$create_keystone_auth        = pick($swift_hash['create_keystone_auth'], true)
$max_header_size             = hiera('max_header_size', '16384')
$openstack_service_endpoints = hiera_hash('openstack_service_endpoints', {})
$admin_ssl_hash              = hiera('internal_ssl')
$keystone_user               = pick($swift_hash['user'], 'swift')
$keystone_password           = pick($swift_hash['user_password'], 'passsword')
$keystone_tenant             = pick($swift_hash['tenant'], 'services')
$swift_operator_roles        = pick($swift_hash['swift_operator_roles'], ['admin', 'SwiftOperator'])
$region                      = hiera('region', 'RegionOne')
$internal_ssl_hash           = hiera('internal_ssl')
$public_ssl_hash             = hiera('public_ssl')
=======
$swift_hash                  = hiera_hash('swift_hash')
$swift_master_role           = hiera('swift_master_role', 'primary-controller')
$swift_nodes                 = pick(hiera('swift_nodes', undef), hiera('controllers', undef))
$swift_proxies_cache         = pick(hiera('swift_proxies_cache', undef), hiera('controller_nodes', undef))
$primary_swift               = pick(hiera('primary_swift', undef), hiera('primary_controller', undef))
$proxy_port                  = hiera('proxy_port', '8080')
$network_scheme              = hiera('network_scheme', {})
$storage_hash                = hiera('storage_hash')
$mp_hash                     = hiera('mp')
$management_vip              = hiera('management_vip')
$public_vip                  = hiera('public_vip')
$debug                       = pick($swift_hash['debug'], hiera('debug', false))
$verbose                     = pick($swift_hash['verbose'], hiera('verbose'))
$storage_address             = hiera('storage_address')
$node                        = hiera('node')
$ring_min_part_hours         = hiera('swift_ring_min_part_hours', 1)
$deploy_swift_storage        = hiera('deploy_swift_storage', true)
$deploy_swift_proxy          = hiera('deploy_swift_proxy', true)
$create_keystone_auth        = pick($swift_hash['create_keystone_auth'], true)
$max_header_size             = hiera('max_header_size', '16384')
$openstack_service_endpoints = hiera_hash('openstack_service_endpoints', {})
$keystone_user               = pick($swift_hash['user'], 'swift')
$keystone_password           = pick($swift_hash['user_password'], 'passsword')
$keystone_tenant             = pick($swift_hash['tenant'], 'services')
$swift_operator_roles        = pick($swift_hash['swift_operator_roles'], ['admin', 'SwiftOperator'])
$region                      = hiera('region', 'RegionOne')
$ssl_hash                    = hiera('use_ssl', {})
>>>>>>> 68ac4bb... Rework selective SSL support

<<<<<<< HEAD
$swift_hash              = hiera_hash('swift_hash')
$swift_master_role       = hiera('swift_master_role', 'primary-controller')
$swift_nodes             = hiera_hash('swift_nodes', {})
$swift_operator_roles    = pick($swift_hash['swift_operator_roles'], ['admin', 'SwiftOperator'])
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
$debug                   = pick($swift_hash['debug'], hiera('debug', false))
$verbose                 = pick($swift_hash['verbose'], hiera('verbose', false))
# NOTE(mattymo): Changing ring_part_power or part_hours on redeploy leads to data loss
$ring_part_power         = pick($swift_hash['ring_part_power'], 10)
$ring_min_part_hours     = hiera('swift_ring_min_part_hours', 1)
$deploy_swift_storage    = hiera('deploy_swift_storage', true)
$deploy_swift_proxy      = hiera('deploy_swift_proxy', true)
$create_keystone_auth    = pick($swift_hash['create_keystone_auth'], true)
#Keystone settings
$service_endpoint        = hiera('service_endpoint')
$keystone_user           = pick($swift_hash['user'], 'swift')
$keystone_password       = pick($swift_hash['user_password'], 'passsword')
$keystone_tenant         = pick($swift_hash['tenant'], 'services')
$keystone_protocol       = pick($swift_hash['auth_protocol'], 'http')
$region                  = hiera('region', 'RegionOne')
$service_workers         = pick($swift_hash['workers'],
                                min(max($::processorcount, 2), 16))
||||||| parent of 68ac4bb... Rework selective SSL support
if $internal_ssl_hash['enable'] or use_ssl($openstack_service_endpoints, 'keystone', 'internal') {
  $keystone_internal_protocol = 'https'
  $keystone_protocol = 'https'
} else {
  $keystone_internal_protocol = 'http'
  $keystone_protocol = 'http'
}
if $public_ssl_hash['enable'] or use_ssl($openstack_service_endpoints, 'keystone', 'public') {
  $keystone_public_protocol = 'https'
} else {
  $keystone_public_protocol = 'http'
}

$keystone_endpoint      = pick(fqdn($openstack_service_endpoints, 'keystone', 'internal'), hiera('keystone_endpoint', ''), hiera('service_endpoint', ''), $management_vip)
$swift_internal_address = pick(fqdn($openstack_service_endpoints, 'swift', 'internal'), $management_vip)
$swift_public_address   = pick(fqdn($openstack_service_endpoints, 'swift', 'public'), $public_vip)
=======
if $ssl_hash['keystone'] and $ssl_hash['keystone_internal'] {
  $keystone_internal_protocol = 'https'
  $keystone_protocol = 'https'
} else {
  $keystone_internal_protocol = 'http'
  $keystone_protocol = 'http'
}
if $ssl_hash['keystone'] and $ssl_hash['keystone_public'] {
  $keystone_public_protocol = 'https'
} else {
  $keystone_public_protocol = 'http'
}

$keystone_endpoint      = pick(fqdn($openstack_service_endpoints, 'keystone', 'internal'), $ssl_hash['keystone_internal_hostname'], hiera('keystone_endpoint', ''), hiera('service_endpoint', ''), $management_vip)
$swift_internal_address = pick($ssl_hash['swift_internal_hostname'], $management_vip)
$swift_public_address   = pick($ssl_hash['swift_public_hostname'], $public_vip)
>>>>>>> 68ac4bb... Rework selective SSL support

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $master_swift_proxy_nodes      = get_nodes_hash_by_roles($network_metadata, [$swift_master_role])
  $master_swift_proxy_nodes_list = values($master_swift_proxy_nodes)
  $master_swift_proxy_ip         = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/api'], '\/\d+$', '')
  $master_swift_replication_ip   = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/replication'], '\/\d+$', '')
  $swift_partition               = hiera('swift_partition', '/var/lib/glance/node')

  if ($deploy_swift_storage){
    if !defined(File['/var/lib/glance']) {
      file {'/var/lib/glance':
        ensure  => 'directory',
        group   => 'swift',
        require => Package['swift'],
      } -> Service <| tag == 'swift-service' |>
    } else {
      File['/var/lib/glance'] {
        ensure  => 'directory',
        group   => 'swift',
        require +> Package['swift'],
      }
      File['/var/lib/glance'] -> Service <| tag == 'swift-service' |>
    }

    class { 'openstack::swift::storage_node':
      storage_type                => false,
      loopback_size               => '5243780',
      storage_mnt_base_dir        => $swift_partition,
      storage_devices             => filter_hash($mp_hash,'point'),
      swift_zone                  => $master_swift_proxy_nodes_list[0]['swift_zone'],
      swift_local_net_ip          => $swift_storage_ipaddr,
      master_swift_proxy_ip       => $master_swift_proxy_ip,
      master_swift_replication_ip => $master_swift_replication_ip,
      sync_rings                  => ! $is_primary_swift_proxy,
      debug                       => $debug,
      verbose                     => $verbose,
      log_facility                => 'LOG_SYSLOG',
    }
  }

  if $is_primary_swift_proxy {
    ring_devices {'all':
      storages => $swift_nodes,
      require  => Class['swift'],
    }
  }

  if $deploy_swift_proxy {
    $sto_nets = get_routable_networks_for_network_role($network_scheme, 'swift/replication', ' ')
    $man_nets = get_routable_networks_for_network_role($network_scheme, 'swift/api', ' ')

    class { 'openstack::swift::proxy':
      swift_user_password            => $swift_hash['user_password'],
      swift_operator_roles           => $swift_operator_roles,
      swift_proxies_cache            => $memcaches_addr_list,
      ring_part_power                => $ring_part_power,
      primary_proxy                  => $is_primary_swift_proxy,
      swift_proxy_local_ipaddr       => $swift_api_ipaddr,
      swift_replication_local_ipaddr => $swift_storage_ipaddr,
      master_swift_proxy_ip          => $master_swift_proxy_ip,
      master_swift_replication_ip    => $master_swift_replication_ip,
      proxy_port                     => $proxy_port,
      proxy_workers                  => $service_workers,
      debug                          => $debug,
      verbose                        => $verbose,
      log_facility                   => 'LOG_SYSLOG',
      ceilometer                     => hiera('use_ceilometer',false),
      ring_min_part_hours            => $ring_min_part_hours,
      admin_user                     => $keystone_user,
      admin_tenant_name              => $keystone_tenant,
      admin_password                 => $keystone_password,
      auth_host                      => $service_endpoint,
      auth_protocol                  => $keystone_protocol,
    } ->
    class { 'openstack::swift::status':
      endpoint    => "http://${swift_api_ipaddr}:${proxy_port}",
      vip         => $management_vip,
      only_from   => "127.0.0.1 240.0.0.2 ${sto_nets} ${man_nets}",
      con_timeout => 5
    } ->
    class { 'swift::dispersion':
      auth_url       => "http://$service_endpoint:5000/v2.0/",
      auth_user      =>  $keystone_user,
      auth_tenant    =>  $keystone_tenant,
      auth_pass      =>  $keystone_password,
      auth_version   =>  '2.0',
    }

    Service<| tag == 'swift-service' |> -> Class['swift::dispersion']

    if defined(Class['openstack::swift::storage_node']) {
      Class['openstack::swift::storage_node'] -> Class['swift::dispersion']
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

