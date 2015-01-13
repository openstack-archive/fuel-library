notice('MODULAR: heat.pp')

$controller_node_public   = hiera('controller_node_public')
$controller_node_address  = hiera('controller_node_address')
$heat_hash                = hiera('heat')
$amqp_hosts               = hiera('amqp_hosts')
$rabbit_hash              = hiera('rabbit')
$max_retries              = hiera('max_retries')
$max_pool_size            = hiera('max_pool_size')
$max_overflow             = hiera('max_overflow')
$idle_timeout             = hiera('idle_timeout')
$debug                    = hiera('debug', false)
$verbose                  = hiera('verbose', true)
$use_syslog               = hiera('use_syslog', true)
$syslog_log_facility_heat = hiera('syslog_log_facility_heat')
$deployment_mode          = hiera('deployment_mode')

#################################################################

class { 'openstack::heat' :
  external_ip         => $controller_node_public,

  keystone_host       => $controller_node_address,
  keystone_user       => 'heat',
  keystone_password   => $heat_hash['user_password'],
  keystone_tenant     => 'services',

  keystone_ec2_uri    => "http://${controller_node_address}:5000/v2.0",

  rpc_backend         => 'heat.openstack.common.rpc.impl_kombu',
  amqp_hosts          => [$amqp_hosts],
  amqp_user           => $rabbit_hash['user'],
  amqp_password       => $rabbit_hash['password'],

  sql_connection      =>
    "mysql://heat:${heat_hash['db_password']}@${$controller_node_address}/heat?read_timeout=60",
  db_host             => $controller_node_address,
  db_password         => $heat_hash['db_password'],
  max_retries         => $max_retries,
  max_pool_size       => $max_pool_size,
  max_overflow        => $max_overflow,
  idle_timeout        => $idle_timeout,

  debug               => $debug,
  verbose             => $verbose,
  use_syslog          => $use_syslog,
  syslog_log_facility => $syslog_log_facility_heat,

  auth_encryption_key => $heat_hash['auth_encryption_key'],
}

if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
  include heat_ha::engine
}

file { '/usr/lib/ocf/resource.d/fuel' :
  ensure => 'directory',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

#------------------------------

class heat::docker_resource (
  $enabled      = true,
  $package_name = 'heat-docker',
) {
  if $enabled {
    package { 'heat-docker':
      ensure => installed,
      name   => $package_name,
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

######################

class mysql::server {}
class mysql::config {}
include mysql::server
include mysql::config
