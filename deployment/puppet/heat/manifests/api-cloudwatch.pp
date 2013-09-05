# Installs & configure the heat CloudWatch API service

class heat::api-cloudwatch (
  $enabled            = true,
  $keystone_host      = '127.0.0.1',
  $keystone_port      = '35357',
  $keystone_protocol  = 'http',
  $keystone_user      = 'heat',
  $keystone_tenant    = 'services',
  $keystone_password  = 'false',
  $keystone_ec2_uri   = 'http://127.0.0.1:5000/v2.0/ec2tokens',
  $auth_uri           = 'http://127.0.0.1:5000/v2.0',
  $bind_host          = '0.0.0.0',
  $bind_port          = '8003',
  $verbose            = 'False',
  $debug              = 'False',
  $rabbit_hosts       = '',
  $rabbit_host        = '127.0.0.1',
  $rabbit_userid      = '',
  $rabbit_ha_queues   = '',
  $rabbit_password    = '',
  $rabbit_virtualhost = '/',
  $rabbit_port        = '5672',
  $log_file           = '/var/log/heat/api-cloudwatch.log',
  $rpc_backend        = 'heat.openstack.common.rpc.impl_kombu',
  $use_stderr         = 'False',
  $use_syslog         = 'False',

) {

  include heat::params

  validate_string($keystone_password)

  Heat_api_cloudwatch_config<||> ~> Service['heat-api-cloudwatch']

  Package['heat-api-cloudwatch'] -> Heat_api_cloudwatch_config<||>
  Package['heat-api-cloudwatch'] -> Service['heat-api-cloudwatch']
  package { 'heat-api-cloudwatch':
    ensure => installed,
    name   => $::heat::params::api_cloudwatch_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Package['heat-common'] -> Service['heat-api-cloudwatch']

  if $rabbit_hosts {
    heat_api_config { 'DEFAULT/rabbit_host': ensure => absent }
    heat_api_config { 'DEFAULT/rabbit_port': ensure => absent }
    heat_api_config { 'DEFAULT/rabbit_hosts':
      value => join($rabbit_hosts, ',')
    }
  } else {
    heat_api_cloudwatch_config { 'DEFAULT/rabbit_host': value => $rabbit_host }
    heat_api_cloudwatch_config { 'DEFAULT/rabbit_port': value => $rabbit_port }
    heat_api_cloudwatch_config { 'DEFAULT/rabbit_hosts':
      value => "${rabbit_host}:${rabbit_port}"
    }
  }

  if size($rabbit_hosts) > 1 {
    heat_api_cloudwatch_config { 'DEFAULT/rabbit_ha_queues': value => true }
  } else {
    heat_api_cloudwatch_config { 'DEFAULT/rabbit_ha_queues': value => false }
  }

  service { 'heat-api-cloudwatch':
    ensure     => $service_ensure,
    name       => $::heat::params::api_cloudwatch_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Class['heat::db'],
  }

  heat_api_cloudwatch_config {
    'DEFAULT/rabbit_userid'                : value => $rabbit_userid;
    'DEFAULT/rabbit_password'              : value => $rabbit_password;
    'DEFAULT/rabbit_virtualhost'           : value => $rabbit_virtualhost;
    'DEFAULT/debug'                        : value => $debug;
    'DEFAULT/verbose'                      : value => $verbose;
    'DEFAULT/log_dir'                      : value => $::heat::params::log_dir;
    'DEFAULT/bind_host'                    : value => $bind_host;
    'DEFAULT/bind_port'                    : value => $bind_port;
    'DEFAULT/log_file'                     : value => $log_file;
    'DEFAULT/rpc_backend'                  : value => $rpc_backend;
    'DEFAULT/use_stderr'                   : value => $use_stderr;
    'DEFAULT/use_syslog'                   : value => $use_syslog;
    'ec2authtoken/keystone_ec2_uri'        : value => $keystone_ec2_uri;
    'ec2authtoken/auth_uri'                : value => $auth_uri;
    'keystone_authtoken/auth_host'         : value => $keystone_host;
    'keystone_authtoken/auth_port'         : value => $keystone_port;
    'keystone_authtoken/auth_protocol'     : value => $keystone_protocol;
    'keystone_authtoken/admin_tenant_name' : value => $keystone_tenant;
    'keystone_authtoken/admin_user'        : value => $keystone_user;
    'keystone_authtoken/admin_password'    : value => $keystone_password;
  }
}
