notice('MODULAR: horizon.pp')

$controllers                    = hiera('controllers')
$controller_internal_addresses  = nodes_to_hash($controllers,'name','internal_address')
$controller_nodes               = ipsort(values($controller_internal_addresses))
$horizon_hash                   = hiera_hash('horizon', {})
$network_config                 = hiera_hash('network', {})

if $horizon_hash['secret_key'] {
  $secret_key = $horizon_hash['secret_key']
} else {
  $secret_key = 'dummy_secret_key'
}

if has_key($network_config, 'neutron_dvr') {
  $neutron_dvr = $network_config['neutron_dvr']
}

$keystone_scheme = 'http'
$keystone_host = hiera('management_vip')
$keystone_port = '5000'
$keystone_api = 'v2.0'
$keystone_url = "${keystone_scheme}://${keystone_host}:${keystone_port}/${keystone_api}"

$neutron_options                = {'enable_distributed_router' => $neutron_dvr}

class { 'openstack::horizon':
  secret_key        => $secret_key,
  cache_server_ip   => hiera('memcache_servers', $controller_nodes),
  package_ensure    => hiera('horizon_package_ensure', 'installed'),
  bind_address      => '*',
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
  neutron_options   => $neutron_options,
}

include ::tweaks::apache_wrappers
