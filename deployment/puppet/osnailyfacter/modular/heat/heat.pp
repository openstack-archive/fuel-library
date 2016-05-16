notice('MODULAR: heat.pp')

prepare_network_config(hiera_hash('network_scheme', {}))
$management_vip           = hiera('management_vip')
$heat_hash                = hiera_hash('heat', {})
$sahara_hash              = hiera_hash('sahara_hash', {})
$rabbit_hash              = hiera_hash('rabbit_hash', {})
$max_retries              = hiera('max_retries')
$max_pool_size            = hiera('max_pool_size')
$max_overflow             = hiera('max_overflow')
$idle_timeout             = hiera('idle_timeout')
$service_endpoint         = hiera('service_endpoint')
$public_ssl_hash          = hiera('public_ssl')
$ssl_hash                 = hiera_hash('use_ssl', {})
$public_vip               = hiera('public_vip')
$primary_controller       = hiera('primary_controller')

$public_auth_protocol     = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'protocol', 'http')
$public_auth_address      = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'hostname', [$public_vip])
$internal_auth_protocol   = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$internal_auth_address    = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
$admin_auth_protocol      = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
$admin_auth_address       = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])

$heat_protocol            = get_ssl_property($ssl_hash, $public_ssl_hash, 'heat', 'public', 'protocol', 'http')
$heat_endpoint            = get_ssl_property($ssl_hash, $public_ssl_hash, 'heat', 'public', 'hostname', [hiera('heat_endpoint', ''), $management_vip])
$internal_ssl             = get_ssl_property($ssl_hash, {}, 'heat', 'internal', 'usage', false)

$public_ssl               = get_ssl_property($ssl_hash, {}, 'heat', 'public', 'usage', false)

$auth_uri                 = "${public_auth_protocol}://${public_auth_address}:5000/v2.0/"
$identity_uri             = "${admin_auth_protocol}://${admin_auth_address}:35357/"

$api_bind_port            = '8004'
$heat_clients_url         = "${heat_protocol}://${public_vip}:${api_bind_port}/v1/%(tenant_id)s"

$debug                    = pick($heat_hash['debug'], hiera('debug', false))
$verbose                  = pick($heat_hash['verbose'], hiera('verbose', true))
$default_log_levels       = hiera_hash('default_log_levels')
$use_stderr               = hiera('use_stderr', false)
$use_syslog               = hiera('use_syslog', true)
$syslog_log_facility_heat = hiera('syslog_log_facility_heat')
$deployment_mode          = hiera('deployment_mode')
$bind_address             = get_network_role_property('heat/api', 'ipaddr')
$memcache_address         = get_network_role_property('mgmt/memcache', 'ipaddr')
$database_password        = $heat_hash['db_password']
$keystone_user            = pick($heat_hash['user'], 'heat')
$keystone_tenant          = pick($heat_hash['tenant'], 'services')
$db_host                  = pick($heat_hash['db_host'], hiera('database_vip'))
$database_user            = pick($heat_hash['db_user'], 'heat')
$database_name            = hiera('heat_db_name', 'heat')
$read_timeout             = '60'
$sql_connection           = "mysql://${database_user}:${database_password}@${db_host}/${database_name}?read_timeout=${read_timeout}"
$region                   = hiera('region', 'RegionOne')
$external_lb              = hiera('external_lb', false)

####### Disable upstart startup on install #######
if $::operatingsystem == 'Ubuntu' {
  tweaks::ubuntu_service_override { 'heat-api-cloudwatch':
    package_name => 'heat-api-cloudwatch',
  }
  tweaks::ubuntu_service_override { 'heat-api-cfn':
    package_name => 'heat-api-cfn',
  }
  tweaks::ubuntu_service_override { 'heat-api':
    package_name => 'heat-api',
  }
  tweaks::ubuntu_service_override { 'heat-engine':
    package_name => 'heat-engine',
  }

  Tweaks::Ubuntu_service_override['heat-api']            -> Service['heat-api']
  Tweaks::Ubuntu_service_override['heat-api-cfn']        -> Service['heat-api-cfn']
  Tweaks::Ubuntu_service_override['heat-api-cloudwatch'] -> Service['heat-api-cloudwatch']
  Tweaks::Ubuntu_service_override['heat-engine']         -> Service['heat-engine']
}

class { 'openstack::heat' :
  external_ip              => $heat_endpoint,
  keystone_auth            => pick($heat_hash['keystone_auth'], true),
  api_bind_host            => $bind_address,
  api_cfn_bind_host        => $bind_address,
  api_cloudwatch_bind_host => $bind_address,
  auth_uri                 => $auth_uri,
  identity_uri             => $identity_uri,
  keystone_protocol        => $keystone_protocol,
  keystone_host            => $service_endpoint,
  keystone_user            => $keystone_user,
  keystone_password        => $heat_hash['user_password'],
  keystone_tenant          => $keystone_tenant,
  keystone_ec2_uri         => "${internal_auth_protocol}://${internal_auth_address}:5000/v2.0",
  region                   => $region,
  rpc_backend              => 'rabbit',
  amqp_hosts               => split(hiera('amqp_hosts',''), ','),
  heat_protocol            => $heat_protocol,
  amqp_user                => $rabbit_hash['user'],
  amqp_password            => $rabbit_hash['password'],
  sql_connection           => $sql_connection,
  db_host                  => $db_host,
  db_password              => $database_password,
  max_retries              => $max_retries,
  max_pool_size            => $max_pool_size,
  max_overflow             => $max_overflow,
  idle_timeout             => $idle_timeout,
  primary_controller       => $primary_controller,
  debug                    => $debug,
  verbose                  => $verbose,
  default_log_levels       => $default_log_levels,
  use_syslog               => $use_syslog,
  use_stderr               => $use_stderr,
  syslog_log_facility      => $syslog_log_facility_heat,
  auth_encryption_key      => $heat_hash['auth_encryption_key'],
}

if hiera('heat_ha_engine', true){
  if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
    include ::heat_ha::engine
  }
}

if $sahara_hash['enabled'] {
  heat_config {
    'DEFAULT/reauthentication_auth_method': value => 'trusts';
  }
}

# Turn on Caching for Heat validation process
heat_config {
  'cache/enabled':          value => true;
  'cache/backend':          value => 'oslo_cache.memcache_pool';
  'cache/memcache_servers': value => "${memcache_address}:11211";
}

# Set heat_clients_url
heat_config {
  'clients_heat/url': value => $heat_clients_url;
}

#------------------------------

class heat::docker_resource (
  $enabled      = true,
  $package_name = 'heat-docker',
) {
  if $enabled {
    package { 'heat-docker':
      ensure  => installed,
      name    => $package_name,
      require => Package['heat-engine'],
    }

    Package['heat-docker'] ~> Service<| title == 'heat-engine' |>
  }
}

if $::osfamily == 'RedHat' {
  $docker_resource_package_name = 'openstack-heat-docker'
} elsif $::osfamily == 'Debian' {
  $docker_resource_package_name = 'heat-docker'
}

class { 'heat::docker_resource' :
  package_name => $docker_resource_package_name,
}

$haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

class {'::osnailyfacter::wait_for_keystone_backends':}

class { 'heat::keystone::domain' :
  auth_url          => "${internal_auth_protocol}://${admin_auth_address}:35357/v2.0",
  keystone_admin    => $keystone_user,
  keystone_password => $heat_hash['user_password'],
  keystone_tenant   => $keystone_tenant,
  domain_name       => 'heat',
  domain_admin      => 'heat_admin',
  domain_password   => $heat_hash['user_password'],
}

Class['heat'] ->
  Class['::osnailyfacter::wait_for_keystone_backends'] ->
    Class['heat::keystone::domain'] ~>
      Service<| title == 'heat-engine' |>

######################

exec { 'wait_for_heat_config' :
  command  => 'sync && sleep 3',
  provider => 'shell',
}

Heat_config <||> -> Exec['wait_for_heat_config'] -> Service['heat-api']
Heat_config <||> -> Exec['wait_for_heat_config'] -> Service['heat-api-cfn']
Heat_config <||> -> Exec['wait_for_heat_config'] -> Service['heat-api-cloudwatch']
Heat_config <||> -> Exec['wait_for_heat_config'] -> Service['heat-engine']

######################

class mysql::server {}
class mysql::config {}
include mysql::server
include mysql::config
