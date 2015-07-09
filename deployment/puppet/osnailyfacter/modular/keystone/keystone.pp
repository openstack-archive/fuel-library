notice('MODULAR: keystone.pp')

$network_scheme = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

$node_name = hiera('node_name')

$verbose               = hiera('verbose', true)
$debug                 = hiera('debug', false)
$use_neutron           = hiera('use_neutron')
$use_syslog            = hiera('use_syslog', true)
$keystone_hash         = hiera_hash('keystone', {})
$access_hash           = hiera_hash('access',{})
$management_vip        = hiera('management_vip')
$database_vip          = hiera('database_vip')
$public_vip            = hiera('public_vip')
$internal_address      = hiera('internal_address')
$glance_hash           = hiera_hash('glance', {})
$nova_hash             = hiera_hash('nova', {})
$cinder_hash           = hiera_hash('cinder', {})
$ceilometer_hash       = hiera_hash('ceilometer', {})
$syslog_log_facility   = hiera('syslog_log_facility_keystone')
$rabbit_hash           = hiera_hash('rabbit_hash', {})
$amqp_hosts            = hiera('amqp_hosts')
$neutron_user_password = hiera('neutron_user_password', false)
$workloads_hash        = hiera_hash('workloads_collector', {})

$db_type     = 'mysql'
$db_host     = pick($keystone_hash['db_host'], $database_vip)
$db_password = $keystone_hash['db_password']
$db_name     = pick($keystone_hash['db_name'], 'keystone')
$db_user     = pick($keystone_hash['db_user'], 'keystone')

$admin_token    = $keystone_hash['admin_token']
$admin_tenant   = $access_hash['tenant']
$admin_email    = $access_hash['email']
$admin_user     = $access_hash['user']
$admin_password = $access_hash['password']
$region         = hiera('region', 'RegionOne')

$public_address   = $public_vip
$admin_address    = $management_vip
$public_bind_host = $internal_address
$admin_bind_host  = $internal_address

$memcache_servers      = hiera('memcache_servers')
$memcache_server_port  = hiera('memcache_server_port', '11211')
$memcache_pool_maxsize = '100'

$public_port = '5000'
$admin_port = '35357'
$internal_port = '5000'
$public_protocol = 'http'

$public_url = "${public_protocol}://${public_address}:${public_port}"
$admin_url = "http://${admin_address}:${admin_port}"
$internal_url = "http://${internal_address}:${internal_port}"

$revoke_driver = 'keystone.contrib.revoke.backends.sql.Revoke'

$glance_user_password     = $glance_hash['user_password']
$nova_user_password       = $nova_hash['user_password']
$cinder_user_password     = $cinder_hash['user_password']
$ceilometer_user_password = $ceilometer_hash['user_password']

$cinder = true
$ceilometer = $ceilometer_hash['enabled']
$enabled = true
$ssl = false

$rabbit_password     = $rabbit_hash['password']
$rabbit_user         = $rabbit_hash['user']
$rabbit_hosts        = split($amqp_hosts, ',')
$rabbit_virtual_host = '/'

$max_pool_size = hiera('max_pool_size')
$max_overflow  = hiera('max_overflow')
$max_retries   = '-1'
$database_idle_timeout  = '3600'

$murano_settings_hash = hiera('murano_settings', {})
if has_key($murano_settings_hash, 'murano_repo_url') {
  $murano_repo_url = $murano_settings_hash['murano_repo_url']
} else {
  $murano_repo_url = 'http://storage.apps.openstack.org'
}

###############################################################################

####### KEYSTONE ###########
class { 'openstack::keystone':
  verbose                  => $verbose,
  debug                    => $debug,
  db_type                  => $db_type,
  db_host                  => $db_host,
  db_password              => $db_password,
  db_name                  => $db_name,
  db_user                  => $db_user,
  admin_token              => $admin_token,
  public_address           => $public_address,
  internal_address         => $management_vip, # send traffic through HAProxy
  admin_address            => $admin_address,
  glance_user_password     => $glance_user_password,
  nova_user_password       => $nova_user_password,
  cinder                   => $cinder,
  cinder_user_password     => $cinder_user_password,
  neutron                  => $use_neutron,
  neutron_user_password    => $neutron_user_password,
  ceilometer               => $ceilometer,
  ceilometer_user_password => $ceilometer_user_password,
  public_bind_host         => $public_bind_host,
  admin_bind_host          => $admin_bind_host,
  enabled                  => $enabled,
  use_syslog               => $use_syslog,
  syslog_log_facility      => $syslog_log_facility,
  region                   => $region,
  memcache_servers         => $memcache_servers,
  memcache_server_port     => $memcache_server_port,
  memcache_pool_maxsize    => $memcache_pool_maxsize,
  max_retries              => $max_retries,
  max_pool_size            => $max_pool_size,
  max_overflow             => $max_overflow,
  rabbit_password          => $rabbit_password,
  rabbit_userid            => $rabbit_user,
  rabbit_hosts             => $rabbit_hosts,
  rabbit_virtual_host      => $rabbit_virtual_host,
  database_idle_timeout    => $database_idle_timeout,
  revoke_driver            => $revoke_driver,
  public_url               => $public_url,
  admin_url                => $admin_url,
  internal_url             => $internal_url,
}

####### WSGI ###########

#class { 'osnailyfacter::apache':
#  listen_ports => hiera_array('apache_ports', ['80', '8888']),
#}

# TODO: (adidenko) use file from package for Debian, when
# https://review.fuel-infra.org/6251 is merged.
#class { 'keystone::wsgi::apache':
#  priority => '05',
#  threads  => 1,
#  workers  => min(max($::processorcount,2), 24),
#  ssl      => $ssl,

#  wsgi_script_ensure => $::osfamily ? {
#    'RedHat'       => 'link',
#    default        => 'file',
#  },
#  wsgi_script_source => $::osfamily ? {
#  # 'Debian'      => '/usr/share/keystone/wsgi.py',
#    'RedHat'       => '/usr/share/keystone/keystone.wsgi',
#    default        => undef,
#  },
#}

#include ::tweaks::apache_wrappers

###############################################################################

class { 'keystone::roles::admin':
  admin        => $admin_user,
  password     => $admin_password,
  email        => $admin_email,
  admin_tenant => $admin_tenant,
}

class { 'openstack::auth_file':
  admin_user      => $admin_user,
  admin_password  => $admin_password,
  admin_tenant    => $admin_tenant,
  region_name     => $region,
  controller_node => $management_vip,
  murano_repo_url => $murano_repo_url,
}

class { 'openstack::workloads_collector':
  enabled               => $workloads_hash['enabled'],
  workloads_username    => $workloads_hash['username'],
  workloads_password    => $workloads_hash['password'],
  workloads_tenant      => $workloads_hash['tenant'],
  workloads_create_user => $workloads_hash['create_user'],
}

Exec <| title == 'keystone-manage db_sync' |> ->
Class['keystone::roles::admin'] ->
Class['openstack::auth_file']

Class['keystone::roles::admin'] ->
Class['openstack::workloads_collector']

$haproxy_stats_url = "http://${management_vip}:10000/;csv"

haproxy_backend_status { 'keystone-public' :
  name => 'keystone-1',
  url  => $haproxy_stats_url,
}

haproxy_backend_status { 'keystone-admin' :
  name => 'keystone-2',
  url  => $haproxy_stats_url,
}

Service['keystone'] -> Haproxy_backend_status<||>
Service<| title == 'httpd' |> -> Haproxy_backend_status<||>
Haproxy_backend_status<||> -> Class['keystone::roles::admin']

####### Disable upstart startup on install #######
if($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { 'keystone':
    package_name => 'keystone',
  }
}
