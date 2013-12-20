class heat::install (
  $keystone_host                 = '127.0.0.1',
  $keystone_port                 = '35357',
  $keystone_service_port         = '5000',
  $keystone_protocol             = 'http',
  $keystone_user                 = 'heat',
  $keystone_tenant               = 'services',
  $keystone_password             = false,
  $keystone_ec2_uri              = 'http://127.0.0.1:5000/v2.0/ec2tokens',
  $auth_uri                      = 'http://127.0.0.1:5000/v2.0',
  $verbose                       = false,
  $debug                         = false,
  $rabbit_hosts                  = '',
  $rabbit_host                   = '127.0.0.1',
  $rabbit_userid                 = '',
  $rabbit_ha_queues              = '',
  $rabbit_password               = '',
  $rabbit_virtualhost            = '/',
  $rabbit_port                   = '5672',
  $rabbit_queue_host             = 'heat',
  $log_file                      = '/var/log/heat/heat.log',
  $log_dir                       = '/var/log/heat',
  $rpc_backend                   = 'heat.openstack.common.rpc.impl_kombu',
  $use_stderr                    = false,
  $use_syslog                    = false,
  $syslog_log_facility           = 'local0',
  $syslog_log_level              = 'WARNING',
  $heat_stack_user_role          = 'heat_stack_user',
  $heat_metadata_server_url      = 'http://127.0.0.1:8000',
  $heat_waitcondition_server_url = 'http://127.0.0.1:8000/v1/waitcondition',
  $heat_watch_server_url         = 'http://127.0.0.1:8003',
  $auth_encryption_key           = '%ENCRYPTION_KEY%',
  $db_backend                    = 'heat.db.sqlalchemy.api',
  $instance_connection_https_validate_certificates = '1',
  $instance_connection_is_secure = '0',
  $api_bind_host                 = '0.0.0.0',
  $api_bind_port                 = '8004',
  $api_cfn_bind_host             = '0.0.0.0',
  $api_cfn_bind_port             = '8000',
  $api_cloudwatch_bind_host      = '0.0.0.0',
  $api_cloudwatch_bind_port      = '8003',
){

  include heat::params

  Package['heat-common'] -> Group['heat'] -> User['heat'] -> File['/etc/heat'] -> File[$log_file] -> File['heat-logging.conf']

  file { '/etc/heat/heat-engine.conf' :
    ensure => symlink,
    target => '/etc/heat/heat.conf'
  } ->
  file { '/etc/heat/heat.conf':
    owner   => 'heat',
    group   => 'heat',
    mode    => '0640',
  }

  group { 'heat' :
    ensure  => present,
    name    => 'heat',
  }

  user { 'heat' :
    ensure  => present,
    name    => 'heat',
    gid     => 'heat',
    groups  => ['heat'],
    system  => true,
  }

  file { '/etc/heat' :
    ensure  => directory,
    owner   => 'heat',
    group   => 'heat',
    mode    => '0750',
  }

  package { 'heat-common' :
    ensure => installed,
    name   => $::heat::params::common_package_name,
  }

  if $rabbit_hosts {
    if is_array($rabbit_hosts) {
      $rabbit_hosts_v = join($rabbit_hosts, ',')
    } else {
      $rabbit_hosts_v = $rabbit_hosts
    }
    heat_config { 'DEFAULT/rabbit_host':  ensure => absent }
    heat_config { 'DEFAULT/rabbit_port':  ensure => absent }
    heat_config { 'DEFAULT/rabbit_hosts': value => $rabbit_hosts_v }
  } else {
    heat_config { 'DEFAULT/rabbit_host': value => $rabbit_host }
    heat_config { 'DEFAULT/rabbit_port': value => $rabbit_port }
    heat_config { 'DEFAULT/rabbit_hosts':
      value => "${rabbit_host}:${rabbit_port}"
    }
  }

  if size($rabbit_hosts) > 1 {
    heat_config { 'DEFAULT/rabbit_ha_queues': value => true }
  } else {
    heat_config { 'DEFAULT/rabbit_ha_queues': value => false }
  }

  file { 'heat-logging.conf' :
    content => template('heat/logging.conf.erb'),
    path    => "/etc/heat/logging.conf",
  }
 
  file { $log_dir :
    ensure  => directory,
    mode    => '0751',
  }
 
  file { $log_file :
    ensure => present,
    mode  => '0640',
  }

  heat_config {
    'DEFAULT/heat_stack_user_role'                            : value => $heat_stack_user_role;
    'DEFAULT/heat_metadata_server_url'                        : value => $heat_metadata_server_url;
    'DEFAULT/heat_waitcondition_server_url'                   : value => $heat_waitcondition_server_url;
    'DEFAULT/heat_watch_server_url'                           : value => $heat_watch_server_url;
    'DEFAULT/auth_encryption_key'                             : value => $auth_encryption_key;
    'DEFAULT/db_backend'                                      : value => $db_backend;
    'DEFAULT/instance_connection_https_validate_certificates' : value => $instance_connection_https_validate_certificates;
    'DEFAULT/instance_connection_is_secure'                   : value => $instance_connection_is_secure;
    'DEFAULT/log_file'                                        : value => $log_file;
    'DEFAULT/rpc_backend'                                     : value => $rpc_backend;
    'DEFAULT/use_stderr'                                      : value => $use_stderr;
    'DEFAULT/use_syslog'                                      : value => $use_syslog;
    'DEFAULT/syslog_log_facility'                             : value => $syslog_log_facility;
    'DEFAULT/rabbit_userid'                                   : value => $rabbit_userid;
    'DEFAULT/rabbit_password'                                 : value => $rabbit_password;
    'DEFAULT/rabbit_virtualhost'                              : value => $rabbit_virtualhost;
    'DEFAULT/debug'                                           : value => $debug;
    'DEFAULT/verbose'                                         : value => $verbose;
    'ec2authtoken/keystone_ec2_uri'                           : value => $keystone_ec2_uri;
    'ec2authtoken/auth_uri'                                   : value => $auth_uri;
    'heat_api_cloudwatch/bind_host'                           : value => $api_cloudwatch_bind_host;
    'heat_api_cloudwatch/bind_port'                           : value => $api_cloudwatch_bind_port;
    'heat_api/bind_host'                                      : value => $api_bind_host;
    'heat_api/bind_port'                                      : value => $api_bind_port;
    'heat_api_cfn/bind_host'                                  : value => $api_cfn_bind_host;
    'heat_api_cfn/bind_port'                                  : value => $api_cfn_bind_port;
    'keystone_authtoken/auth_host'                            : value => $keystone_host;
    'keystone_authtoken/auth_port'                            : value => $keystone_port;
    'keystone_authtoken/auth_protocol'                        : value => $keystone_protocol;
    'keystone_authtoken/admin_tenant_name'                    : value => $keystone_tenant;
    'keystone_authtoken/admin_user'                           : value => $keystone_user;
    'keystone_authtoken/admin_password'                       : value => $keystone_password;
    'keystone_authtoken/auth_uri'                             : value => "${keystone_protocol}://${keystone_host}:${keystone_service_port}/v2.0";
  }

}
