notice('MODULAR: horizon.pp')

$controllers                    = hiera('controllers')
$controller_internal_addresses  = nodes_to_hash($controllers,'name','internal_address')
$controller_nodes               = ipsort(values($controller_internal_addresses))
$horizon_hash                   = hiera('horizon', {})

if $horizon_hash['secret_key'] {
  $secret_key = $horizon_hash['secret_key']
} else {
  $secret_key = 'dummy_secret_key'
}

class { 'openstack::horizon':
  secret_key        => $secret_key,
  cache_server_ip   => $controller_nodes,
  package_ensure    => hiera('horizon_package_ensure', 'installed'),
  bind_address      => '*',
  cache_server_port => '11211',
  cache_backend     => 'horizon.backends.memcached.HorizonMemcached',
  cache_options     => ["'SOCKET_TIMEOUT': 1","'SERVER_RETRIES': 1","'DEAD_RETRY': 1"],
  neutron           => hiera('use_neutron'),
  keystone_host     => hiera('management_vip'),
  use_ssl           => hiera('horizon_use_ssl', false),
  verbose           => hiera('verbose', true),
  debug             => hiera('debug'),
  use_syslog        => hiera('use_syslog', true),
  nova_quota        => hiera('nova_quota'),
  servername        => hiera('public_vip'),
}

include ::tweaks::apache_wrappers
