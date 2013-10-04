class heat::api (
  $enabled            = true,
  $keystone_host      = '127.0.0.1',
  $keystone_port      = '35357',
  $keystone_protocol  = 'http',
  $keystone_user      = 'heat',
  $keystone_tenant    = 'services',
  $keystone_password  = false,
  $keystone_ec2_uri   = 'http://127.0.0.1:5000/v2.0/ec2tokens',
  $auth_uri           = 'http://127.0.0.1:5000/v2.0',
  $bind_host          = '0.0.0.0',
  $bind_port          = '8004',
  $verbose            = 'False',
  $debug              = 'False',
  $rabbit_hosts       = '',
  $rabbit_host        = '127.0.0.1',
  $rabbit_userid      = '',
  $rabbit_ha_queues   = '',
  $rabbit_password    = '',
  $rabbit_virtualhost = '/',
  $rabbit_port        = '5672',
  $log_file           = '/var/log/heat/api.log',
  $rpc_backend        = 'heat.openstack.common.rpc.impl_kombu',
  $use_stderr         = 'False',
  $use_syslog         = 'False',
  $keystone_service_port  = '5000',
) {

  include heat::params

  validate_string($keystone_password)

  package { 'python-routes':
    ensure => installed,
    name   => $::heat::params::deps_routes_package_name,
  }

  package { 'heat-api':
    ensure  => installed,
    name    => $::heat::params::api_package_name,
    require => Package['python-routes'],
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if $rabbit_hosts {
    heat_api_config { 'DEFAULT/rabbit_host':  ensure => absent }
    heat_api_config { 'DEFAULT/rabbit_port':  ensure => absent }
    heat_api_config { 'DEFAULT/rabbit_hosts': value => join($rabbit_hosts, ',') }
  } else {
    heat_api_config { 'DEFAULT/rabbit_host':  value => $rabbit_host }
    heat_api_config { 'DEFAULT/rabbit_port':  value => $rabbit_port }
    heat_api_config { 'DEFAULT/rabbit_hosts': value => "${rabbit_host}:${rabbit_port}" }
  }

  if size($rabbit_hosts) > 1 {
    heat_api_config { 'DEFAULT/rabbit_ha_queues': value => true }
  } else {
    heat_api_config { 'DEFAULT/rabbit_ha_queues': value => false }
  }

  service { 'heat-api':
    ensure     => $service_ensure,
    name       => $::heat::params::api_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  heat_api_config {
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
    'keystone_authtoken/auth_uri'          : value => "${keystone_protocol}://${keystone_host}:${keystone_service_port}/v2";
  }

  Package['heat-common'] -> Package['heat-api'] -> Heat_api_config<||> ~> Service['heat-api']
  Package['heat-api'] ~> Service['heat-api']
  Class['heat::db'] -> Service['heat-api']

}
