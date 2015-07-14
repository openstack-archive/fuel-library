notice('MODULAR: horizon.pp')

prepare_network_config(hiera('network_scheme', {}))
$horizon_hash         = hiera_hash('horizon', {})
$bind_address         = get_network_role_property('horizon', 'ipaddr')
$memcache_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('memcache_nodes'), 'mgmt/memcache')

if $horizon_hash['secret_key'] {
  $secret_key = $horizon_hash['secret_key']
} else {
  $secret_key = 'dummy_secret_key'
}

$keystone_scheme = 'http'
$keystone_host = hiera('management_vip')
$keystone_port = '5000'
$keystone_api = 'v2.0'
$keystone_url = "${keystone_scheme}://${keystone_host}:${keystone_port}/${keystone_api}"

class { 'openstack::horizon':
  secret_key        => $secret_key,
  cache_server_ip   => ipsort(values($memcache_address_map)),
  package_ensure    => hiera('horizon_package_ensure', 'installed'),
  bind_address      => $bind_address,
  cache_server_port => hiera('memcache_server_port', '11211'),
  cache_backend     => 'django.core.cache.backends.memcached.MemcachedCache',
  neutron           => hiera('use_neutron'),
  keystone_url      => $keystone_url,
  use_ssl           => hiera('horizon_use_ssl', false),
  verbose           => hiera('verbose', true),
  debug             => hiera('debug'),
  use_syslog        => hiera('use_syslog', true),
  nova_quota        => hiera('nova_quota'),
  servername        => hiera('public_vip'),
}

include ::tweaks::apache_wrappers
