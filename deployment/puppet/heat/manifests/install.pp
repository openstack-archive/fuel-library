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

  $rabbit_hosts                  = '',
  $rabbit_host                   = '127.0.0.1',
  $rabbit_userid                 = '',
  $rabbit_ha_queues              = '',
  $rabbit_password               = '',
  $rabbit_virtualhost            = '/',
  $rabbit_port                   = '5672',
  $rabbit_queue_host             = 'heat',

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

  $logging_file = '/etc/heat/logging.conf'
  #$logging_context_format_string = 'heat %(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s [%(request_id)s %(user)s %(tenant)s] %(instance)s%(message)s'
  #$logging_default_format_string = 'heat %(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s'

  if $use_syslog and !$debug {
    heat_config {
      'DEFAULT/log_config' : value => $logging_file;
      'DEFAULT/use_syslog' : value => true;
    }
    file { 'heat-logging.conf' :
      ensure  => present,
      content => template('heat/logging.conf.erb'),
      path    => $logging_file,
    }
  } else {
    heat_config {
      'DEFAULT/log_config' : ensure => absent;
      'DEFAULT/use_syslog' : value => false;
    }
    file { 'heat-logging.conf' :
      ensure  => absent,
      path    => $logging_file,
    }
  }

  File['heat-logging.conf'] -> Heat_config['DEFAULT/log_config']
  File['heat-logging.conf'] ~> Service <| title == 'heat-api-cfn' |>
  File['heat-logging.conf'] ~> Service <| title == 'heat-api-cloudwatch' |>
  File['heat-logging.conf'] ~> Service <| title == 'heat-api' |>
  File['heat-logging.conf'] ~> Service <| title == 'heat-engine' |>

  heat_config {
    'DEFAULT/heat_stack_user_role'                            : value => $heat_stack_user_role;
    'DEFAULT/heat_metadata_server_url'                        : value => $heat_metadata_server_url;
    'DEFAULT/heat_waitcondition_server_url'                   : value => $heat_waitcondition_server_url;
    'DEFAULT/heat_watch_server_url'                           : value => $heat_watch_server_url;
    'DEFAULT/auth_encryption_key'                             : value => $auth_encryption_key;
    'DEFAULT/db_backend'                                      : value => $db_backend;
    'DEFAULT/instance_connection_https_validate_certificates' : value => $ic_https_validate_certs;
    'DEFAULT/instance_connection_is_secure'                   : value => $ic_is_secure;
    'DEFAULT/log_dir'                                         : value => $log_dir;
    'DEFAULT/log_file'                                        : ensure => absent;
    'DEFAULT/rpc_backend'                                     : value => $rpc_backend;
    'DEFAULT/use_stderr'                                      : value => $use_stderr;
    #'DEFAULT/logging_context_format_string'                   : value => $logging_context_format_string;
    #'DEFAULT/logging_default_format_string'                   : value => $logging_default_format_string;
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
