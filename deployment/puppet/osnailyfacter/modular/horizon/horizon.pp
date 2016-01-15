notice('MODULAR: horizon.pp')

prepare_network_config(hiera('network_scheme', {}))
$horizon_hash            = hiera_hash('horizon', {})
$service_endpoint        = hiera('service_endpoint')
$memcached_server        = hiera('memcached_addresses')
$bind_address            = get_network_role_property('horizon', 'ipaddr')
$neutron_advanced_config = hiera_hash('neutron_advanced_configuration', {})
$public_ssl              = hiera('public_ssl')
$ssl_no_verify           = $public_ssl['horizon']
$overview_days_range     = pick($horizon_hash['overview_days_range'], 1)
$external_lb             = hiera('external_lb', false)

if $horizon_hash['secret_key'] {
  $secret_key = $horizon_hash['secret_key']
} else {
  $secret_key = 'dummy_secret_key'
}

# TODO(aschultz): the horizon.backends.memcached.HorizonMemcached is only part
# of the MOS package set. This should be contributed upstream and then we can
# use this as the default.
if !$::os_package_type or $::os_package_type == 'debian' {
  $horizon_cache_backend = try_get_value($horizon_hash, 'cache_backend', 'horizon.backends.memcached.HorizonMemcached')
} else {
  $horizon_cache_backend = try_get_value($horizon_hash, 'cache_backend', 'django.core.cache.backends.memcached.MemcachedCache')
}

$neutron_dvr = pick($neutron_advanced_config['neutron_dvr'], false)

$ssl_hash               = hiera_hash('use_ssl', {})
$internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
$internal_auth_port     = '5000'
$keystone_api           = 'v2.0'
$keystone_url           = "${internal_auth_protocol}://${internal_auth_address}:${internal_auth_port}/${keystone_api}"

$neutron_options    = {'enable_distributed_router' => $neutron_dvr}
$hypervisor_options = {'enable_quotas' => hiera('nova_quota')}

$temp_root_default = '/var/lib/horizon'
$temp_root_is_dir = inline_template('<%= File.directory?(@temp_root_default) %>')

if $temp_root_is_dir == 'false' {
  $temp_root_prefix = ''
}
else {
  $temp_root_prefix = $temp_root_default
}

$file_upload_temp_dir = pick($horizon_hash['upload_dir'], "${temp_root_prefix}/tmp")

# 10G by default
$file_upload_max_size = pick($horizon_hash['upload_max_size'], 10737418235)

class { 'openstack::horizon':
  secret_key           => $secret_key,
  cache_server_ip      => $memcached_server,
  package_ensure       => hiera('horizon_package_ensure', 'installed'),
  bind_address         => $bind_address,
  cache_server_port    => hiera('memcache_server_port', '11211'),
  cache_backend        => $horizon_cache_backend,
  cache_options        => {'SOCKET_TIMEOUT' => 1,'SERVER_RETRIES' => 1,'DEAD_RETRY' => 1},
  neutron              => hiera('use_neutron'),
  keystone_url         => $keystone_url,
  use_ssl              => hiera('horizon_use_ssl', false),
  ssl_no_verify        => $ssl_no_verify,
  verbose              => pick($horizon_hash['verbose'], hiera('verbose', true)),
  debug                => pick($horizon_hash['debug'], hiera('debug')),
  use_syslog           => hiera('use_syslog', true),
  hypervisor_options   => $hypervisor_options,
  servername           => hiera('public_vip'),
  neutron_options      => $neutron_options,
  overview_days_range  => $overview_days_range,
  file_upload_temp_dir => $file_upload_temp_dir,
  file_upload_max_size => $file_upload_max_size,
}

$haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

if $external_lb {
  Haproxy_backend_status<||> {
    provider => 'http',
  }
  $admin_identity_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_url      = "${admin_identity_protocol}://${admin_identity_address}:35357"
}

haproxy_backend_status { 'keystone-public' :
  name  => 'keystone-1',
  count => '30',
  step  => '3',
  url   => $external_lb ? {
    default => $haproxy_stats_url,
    true    => $keystone_url,
  },
}

haproxy_backend_status { 'keystone-admin' :
  name  => 'keystone-2',
  count => '30',
  step  => '3',
  url   => $external_lb ? {
    default => $haproxy_stats_url,
    true    => $admin_identity_url,
  },
}

Class['openstack::horizon'] -> Haproxy_backend_status['keystone-admin']
Class['openstack::horizon'] -> Haproxy_backend_status['keystone-public']

# TODO(aschultz): remove this if openstack-dashboard stops installing
# openstack-dashboard-apache in Debian packages
#
# In UCA 'openstack-dashboard-apache' package has never existed
if $::os_package_type == 'debian' {
  # LP#1513252 - remove this package if it's installed by the
  # openstack-dashboard package installation.
  Package <| name == 'openstack-dashboard-apache' |> {
    ensure  => 'absent',
    require => Package['openstack-dashboard']
  } ~> Service[$::apache::params::service_name]

  package { 'openstack-dashboard':
    ensure => present,
  }
}

include ::tweaks::apache_wrappers
