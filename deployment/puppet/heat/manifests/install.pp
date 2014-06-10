class heat::install (
  $keystone_host                 = '127.0.0.1',
  $keystone_port                 = '35357',
  $keystone_service_port         = '5000',
  $keystone_protocol             = 'http',
  $keystone_user                 = 'heat',
  $keystone_tenant               = 'services',
  $keystone_password             = 'heat',
  $keystone_ec2_uri              = 'http://127.0.0.1:5000/v2.0/ec2tokens',
  $rpc_backend                   = 'heat.openstack.common.rpc.impl_kombu',
  $auth_uri                      = 'http://127.0.0.1:5000/v2.0',

  $verbose                       = false,
  $debug                         = false,
  $use_stderr                    = false,
  $use_syslog                    = false,
  $syslog_log_facility           = 'LOG_LOCAL0',
  $log_dir                       = '/var/log/heat',

  $amqp_hosts                    = '127.0.0.1',
  $amqp_user                     = 'heat',
  $amqp_password                 = 'heat',
  $rabbit_ha_queues              = false,
  $rabbit_virtualhost            = '/',

  $heat_stack_user_role          = 'heat_stack_user',
  $heat_metadata_server_url      = 'http://127.0.0.1:8000',
  $heat_waitcondition_server_url = 'http://127.0.0.1:8000/v1/waitcondition',
  $heat_watch_server_url         = 'http://127.0.0.1:8003',
  $auth_encryption_key           = '%ENCRYPTION_KEY%',
  $db_backend                    = 'heat.db.sqlalchemy.api',
  $ic_https_validate_certs       = '1',
  $ic_is_secure                  = '0',

  $api_bind_host                 = '0.0.0.0',
  $api_bind_port                 = '8004',
  $api_cfn_bind_host             = '0.0.0.0',
  $api_cfn_bind_port             = '8000',
  $api_cloudwatch_bind_host      = '0.0.0.0',
  $api_cloudwatch_bind_port      = '8003',
){

  include heat::params

 Package['heat-common'] -> Group['heat'] -> User['heat'] -> File['/etc/heat']

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

  # Log configuration
  if $log_dir {
    heat_config {
      'DEFAULT/log_dir' : value  => $log_dir;
    }
  } else {
    heat_config {
      'DEFAULT/log_dir' : ensure => absent;
    }
  }

  # Syslog configuration
  if $use_syslog {
    heat_config {
      'DEFAULT/use_syslog':            value => true;
      'DEFAULT/use_syslog_rfc_format': value => true;
      'DEFAULT/syslog_log_facility':   value => $syslog_log_facility;
    }
  } else {
    heat_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

  heat_config {
    'DEFAULT/heat_stack_user_role'                            : value => $heat_stack_user_role;
    'DEFAULT/heat_metadata_server_url'                        : value => $heat_metadata_server_url;
    'DEFAULT/heat_waitcondition_server_url'                   : value => $heat_waitcondition_server_url;
    'DEFAULT/heat_watch_server_url'                           : value => $heat_watch_server_url;
    'DEFAULT/auth_encryption_key'                             : value => $auth_encryption_key;
    'DEFAULT/db_backend'                                      : value => $db_backend;
    'DEFAULT/instance_connection_https_validate_certificates' : value => $ic_https_validate_certs;
    'DEFAULT/instance_connection_is_secure'                   : value => $ic_is_secure;
    'DEFAULT/rpc_backend'                                     : value => $rpc_backend;
    'DEFAULT/use_stderr'                                      : value => $use_stderr;
    'DEFAULT/rabbit_hosts'                                    : value => $amqp_hosts;
    'DEFAULT/rabbit_userid'                                   : value => $amqp_user;
    'DEFAULT/rabbit_password'                                 : value => $amqp_password;
    'DEFAULT/rabbit_ha_queues'                                : value => $rabbit_ha_queues;
    'DEFAULT/rabbit_virtualhost'                              : value => $rabbit_virtualhost;
    'DEFAULT/kombu_reconnect_delay'                           : value       => '5.0';
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
