class heat::api_cfn (
  $pacemaker          = false,
  $keystone_host      = '127.0.0.1',
  $keystone_port      = '35357',
  $keystone_service_port = '5000',
  $keystone_protocol  = 'http',
  $keystone_user      = 'heat',
  $keystone_tenant    = 'services',
  $keystone_password  = false,
  $keystone_ec2_uri   = 'http://127.0.0.1:5000/v2.0/ec2tokens',
  $auth_uri           = 'http://127.0.0.1:5000/v2.0',
  $bind_host          = '0.0.0.0',
  $bind_port          = '8000',
  $verbose            = 'False',
  $debug              = 'False',
  $rabbit_hosts       = '',
  $rabbit_host        = '127.0.0.1',
  $rabbit_userid      = '',
  $rabbit_ha_queues   = '',
  $rabbit_password    = '',
  $rabbit_virtualhost = '/',
  $rabbit_port        = '5672',
  $rabbit_queue_host  = 'heat',
  $log_file           = '/var/log/heat/api-cloudwatch.log',
  $rpc_backend        = 'heat.openstack.common.rpc.impl_kombu',
  $use_stderr         = 'False',
  $use_syslog         = 'False',
  $firewall_rule_name = '205 heat-api-cfn',

) {

  include heat::params

  validate_string($keystone_password)

  package { 'heat-api-cfn':
    ensure => installed,
    name   => $::heat::params::api_cfn_package_name,
  }

  if $rabbit_hosts {
    heat_api_cfn_config { 'DEFAULT/rabbit_host':  ensure => absent }
    heat_api_cfn_config { 'DEFAULT/rabbit_port':  ensure => absent }
    heat_api_cfn_config { 'DEFAULT/rabbit_hosts': value => join($rabbit_hosts, ',') }
  } else {
    heat_api_cfn_config { 'DEFAULT/rabbit_host':  value => $rabbit_host }
    heat_api_cfn_config { 'DEFAULT/rabbit_port':  value => $rabbit_port }
    heat_api_cfn_config { 'DEFAULT/rabbit_hosts': value => "${rabbit_host}:${rabbit_port}" }
  }

  if size($rabbit_hosts) > 1 {
    heat_api_cfn_config { 'DEFAULT/rabbit_ha_queues': value => true }
  } else {
    heat_api_cfn_config { 'DEFAULT/rabbit_ha_queues': value => false }
  }

  service { 'heat-api-cfn':
    ensure     => 'running',
    name       => $::heat::params::api_cfn_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  heat_api_cfn_config {
    'DEFAULT/rabbit_userid'                : value => $rabbit_userid;
    'DEFAULT/rabbit_password'              : value => $rabbit_password;
    'DEFAULT/rabbit_virtualhost'           : value => $rabbit_virtualhost;
    'DEFAULT/host'                         : value => $rabbit_queue_host;
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
    'keystone_authtoken/auth_uri'          : value => "${keystone_protocol}${keystone_host}:5000/v2";
  }
  
  heat_api_cfn_paste_ini {
    'filter:authtoken/paste.filter_factory' : value => "heat.common.auth_token:filter_factory";
    'filter:authtoken/service_protocol'     : value => $keystone_protocol;
    'filter:authtoken/service_host'         : value => $keystone_host;
    'filter:authtoken/service_port'         : value => $keystone_service_port;
    'filter:authtoken/auth_host'            : value => $keystone_host;
    'filter:authtoken/auth_port'            : value => $keystone_port;
    'filter:authtoken/auth_protocol'        : value => $keystone_protocol;
    'filter:authtoken/auth_uri'             : value => "${keystone_protocol}://${keystone_host}:${keystone_port}/v2.0";
    'filter:authtoken/admin_tenant_name'    : value => $keystone_tenant;
    'filter:authtoken/admin_user'           : value => $keystone_user;
    'filter:authtoken/admin_password'       : value => $keystone_password;
  }

  firewall { $firewall_rule_name :
    dport   => [ $bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  Package['heat-common'] -> Package['heat-api-cfn'] -> Heat_api_cfn_config<||> -> Heat_api_cfn_paste_ini<||>
  Heat_api_cfn_config<||> ~> Service['heat-api-cfn']
  Heat_api_cfn_paste_ini<||> ~> Service['heat-api-cfn']
  Package['heat-api-cfn'] ~> Service['heat-api-cfn']
  Class['heat::db'] -> Service['heat-api-cfn']
  Exec['heat_db_sync'] -> Service['heat-api-cfn'] 

}
