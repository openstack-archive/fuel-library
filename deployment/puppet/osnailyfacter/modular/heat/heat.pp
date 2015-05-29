notice('MODULAR: heat.pp')

$controller_node_public   = hiera('controller_node_public')
$controller_node_address  = hiera('controller_node_address')
$management_vip           = hiera('management_vip')
$heat_hash                = hiera_hash('heat', {})
$amqp_hosts               = hiera('amqp_hosts')
$rabbit_hash              = hiera_hash('rabbit_hash', {})
$max_retries              = hiera('max_retries')
$max_pool_size            = hiera('max_pool_size')
$max_overflow             = hiera('max_overflow')
$idle_timeout             = hiera('idle_timeout')
$service_endpoint         = hiera('service_endpoint', $management_vip)
$debug                    = hiera('debug', false)
$verbose                  = hiera('verbose', true)
$use_syslog               = hiera('use_syslog', true)
$syslog_log_facility_heat = hiera('syslog_log_facility_heat')
$deployment_mode          = hiera('deployment_mode')
$internal_address         = hiera('internal_address')
$database_password        = $heat_hash['db_password']
$keystone_user            = $heat_hash['user'] ? {
  default => $heat_hash['user'],
  undef   => 'heat',
}
$keystone_tenant          = $heat_hash['tenant'] ? {
  default => $heat_hash['tenant'],
  undef   => 'services',
}
$db_host                  = $heat_hash['db_host'] ? {
  default => $heat_hash['db_host'],
  undef   => $management_vip,
}
$database_user            = $heat_hash['db_user'] ? {
  default => $heat_hash['db_user'],
  undef   => 'heat',
}
$database_name            = hiera('heat_db_name', 'heat')
$read_timeout             = '60'
$sql_connection           = "mysql://${database_user}:${database_password}@${db_host}/${database_name}?read_timeout=${read_timeout}"

####### Disable upstart startup on install #######
if($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { 'heat-api-cloudwatch':
    package_name => 'heat-api-cloudwatch',
  }
  tweaks::ubuntu_service_override { 'heat-api-cfn':
    package_name => 'heat-api-cfn',
  }
  tweaks::ubuntu_service_override { 'heat-api':
    package_name => 'heat-api',
  }
}

class { 'openstack::heat' :
  external_ip              => $controller_node_public,
  keystone_auth            => $heat_hash['keystone_auth'] ? {
    default                => $heat_hash['keystone_auth'],
    undef                  => true,
  },
  create_heat_db           => $heat_hash['create_heat_db'] ? {
    default                => $heat_hash['create_heat_db'],
    undef                  => true,
  },
  api_bind_host            => $internal_address,
  api_cfn_bind_host        => $internal_address,
  api_cloudwatch_bind_host => $internal_address,

  keystone_host            => $service_endpoint,
  keystone_user            => $keystone_user,
  keystone_password        => $heat_hash['user_password'],
  keystone_tenant          => $keystone_tenant,

  keystone_ec2_uri         => "http://${service_endpoint}:5000/v2.0",

  rpc_backend              => 'heat.openstack.common.rpc.impl_kombu',
  amqp_hosts               => [$amqp_hosts],
  amqp_user                => $rabbit_hash['user'],
  amqp_password            => $rabbit_hash['password'],

  sql_connection           => $sql_connection,
  db_host                  => $db_host,
  db_password              => $database_password,
  max_retries              => $max_retries,
  max_pool_size            => $max_pool_size,
  max_overflow             => $max_overflow,
  idle_timeout             => $idle_timeout,

  debug                    => $debug,
  verbose                  => $verbose,
  use_syslog               => $use_syslog,
  syslog_log_facility      => $syslog_log_facility_heat,

  auth_encryption_key      => $heat_hash['auth_encryption_key'],
}

if hiera('heat_ha_engine', true){
  if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
    include heat_ha::engine
  }
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

class { 'heat::keystone::domain' :
  auth_url          => "http://${controller_node_address}:35357/v2.0",
  keystone_admin    => $keystone_user,
  keystone_password => $heat_hash['user_password'],
  keystone_tenant   => $keystone_tenant,
  domain_name       => 'heat',
  domain_admin      => 'heat_admin',
  domain_password   => $heat_hash['user_password'],
}

Class['heat'] -> Class['heat::keystone::domain'] ~> Service<| title == 'heat-engine' |>

heat_config {
  'DEFAULT/deferred_auth_method'    : value => 'trusts';
  'DEFAULT/trusts_delegated_roles'  : value => '';
}

######################

class mysql::server {}
class mysql::config {}
include mysql::server
include mysql::config
