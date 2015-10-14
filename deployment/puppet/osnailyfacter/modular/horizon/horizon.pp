notice('MODULAR: horizon.pp')

prepare_network_config(hiera('network_scheme', {}))
$horizon_hash            = hiera_hash('horizon', {})
$service_endpoint        = hiera('service_endpoint')
$memcache_nodes          = get_nodes_hash_by_roles(hiera('network_metadata'), hiera('memcache_roles'))
$memcache_address_map    = get_node_to_ipaddr_map_by_network_role($memcache_nodes, 'mgmt/memcache')
$bind_address            = get_network_role_property('horizon', 'ipaddr')
$neutron_advanced_config = hiera_hash('neutron_advanced_configuration', {})
$public_ssl              = hiera('public_ssl')
$ssl_no_verify           = $public_ssl['horizon']

if $horizon_hash['secret_key'] {
  $secret_key = $horizon_hash['secret_key']
} else {
  $secret_key = 'dummy_secret_key'
}

$neutron_dvr = pick($neutron_advanced_config['neutron_dvr'], false)

$keystone_scheme = 'http'
$keystone_host = $service_endpoint
$keystone_port = '5000'
$keystone_api = 'v2.0'
$keystone_url = "${keystone_scheme}://${keystone_host}:${keystone_port}/${keystone_api}"

$neutron_options                = {'enable_distributed_router' => $neutron_dvr}

class { 'openstack::horizon':
  secret_key        => $secret_key,
  cache_server_ip   => ipsort(values($memcache_address_map)),
  package_ensure    => hiera('horizon_package_ensure', 'installed'),
  bind_address      => $bind_address,
  cache_server_port => hiera('memcache_server_port', '11211'),
  cache_backend     => 'django.core.cache.backends.memcached.MemcachedCache',
  cache_options     => {'SOCKET_TIMEOUT' => 1,'SERVER_RETRIES' => 1,'DEAD_RETRY' => 1},
  neutron           => hiera('use_neutron'),
  keystone_url      => $keystone_url,
  use_ssl           => hiera('horizon_use_ssl', false),
  ssl_no_verify     => $ssl_no_verify,
  verbose           => pick($horizon_hash['verbose'], hiera('verbose', true)),
  debug             => pick($horizon_hash['debug'], hiera('debug')),
  use_syslog        => hiera('use_syslog', true),
  nova_quota        => hiera('nova_quota'),
  servername        => hiera('public_vip'),
  neutron_options   => $neutron_options,
}

$haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

haproxy_backend_status { 'keystone-admin' :
  name  => 'keystone-2',
  count => '30',
  step  => '3',
  url   => $haproxy_stats_url,
}

haproxy_backend_status { 'keystone-public' :
  name  => 'keystone-1',
  count => '30',
  step  => '3',
  url   => $haproxy_stats_url,
}

Class['openstack::horizon'] -> Haproxy_backend_status['keystone-admin']
Class['openstack::horizon'] -> Haproxy_backend_status['keystone-public']

include ::tweaks::apache_wrappers
