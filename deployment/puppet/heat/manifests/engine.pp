# Installs & configure the heat engine service

class heat::engine (
  $enabled           = true,
  $keystone_host     = '127.0.0.1',
  $keystone_port     = '35357',
  $keystone_protocol = 'http',
  $keystone_user     = 'heat',
  $keystone_tenant   = 'services',
  $keystone_password = 'password',
  $bind_host         = '0.0.0.0',
  $bind_port         = '8001',
  $verbose           = 'False',
  $debug             = 'False',
  $heat_stack_user_role          = 'heat_stack_user',
  $heat_metadata_server_url      = 'http://127.0.0.1:8000',
  $heat_waitcondition_server_url = 'http://127.0.0.1:8000/v1/waitcondition',
  $heat_watch_server_url         = 'http://127.0.0.1:8003',
  $rabbit_hosts                  = '',
  $rabbit_host                   = '',
  $rabbit_userid                 = '',
  $rabbit_ha_queues              = '',
  $rabbit_password               = '',
  $rabbit_virtualhost            = '/',
  $rabbit_port                   = '5672',
  $auth_encryption_key           = '%ENCRYPTION_KEY%',
  $db_backend                    = 'heat.db.sqlalchemy.api',
  $instance_connection_https_validate_certificates = '1',
  $instance_connection_is_secure = '0',
  $log_file                      = '/var/log/heat/engine.log',
  $rpc_backend                   = 'heat.openstack.common.rpc.impl_kombu',
  $use_stderr                    = 'False',
  $use_syslog                    = 'False',






) {

  include heat::params

  validate_string($keystone_password)

  Heat_engine_config<||> ~> Service['heat-engine']

  Package['heat-engine'] -> Heat_engine_config<||>
  Package['heat-engine'] -> Service['heat-engine']
  package { 'heat-engine':
    ensure => installed,
    name   => $::heat::params::engine_package_name,
  }

  file { '/etc/heat/heat-engine.conf':
    owner   => 'heat',
    group   => 'heat',
    mode    => '0640',
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if $rabbit_hosts {
    if  is_array($rabbit_hosts) {
      $rabbit_hosts_v = join($rabbit_hosts, ',')
    } else {
      $rabbit_hosts_v = $rabbit_hosts
    }
    heat_engine_config { 'DEFAULT/rabbit_host': ensure => absent }
    heat_engine_config { 'DEFAULT/rabbit_port': ensure => absent }
    heat_engine_config { 'DEFAULT/rabbit_hosts': value => $rabbit_hosts_v }
  } else {
    heat_engine_config { 'DEFAULT/rabbit_host': value => $rabbit_host }
    heat_engine_config { 'DEFAULT/rabbit_port': value => $rabbit_port }
    heat_engine_config { 'DEFAULT/rabbit_hosts':
      value => "${rabbit_host}:${rabbit_port}"
    }
  }

  if size($rabbit_hosts) > 1 {
    heat_engine_config { 'DEFAULT/rabbit_ha_queues': value => true }
  } else {
    heat_engine_config { 'DEFAULT/rabbit_ha_queues': value => false }
  }


  service { 'heat-engine':
    ensure     => $service_ensure,
    name       => $::heat::params::engine_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => [ File['/etc/heat/heat-engine.conf'],
                    Exec['heat-encryption-key-replacement'],
                    Package['heat-common'],
		    Package['heat-engine'],
		    Class['heat::db']],
  }

  exec {'heat-encryption-key-replacement':
    command => 'sed -i "s/%ENCRYPTION_KEY%/`hexdump -n 16 -v -e \'/1 "%02x"\' /dev/random`/" /etc/heat/heat-engine.conf',
    path => [ '/usr/bin', '/bin'],
    onlyif => 'grep -c ENCRYPTION_KEY /etc/heat/heat-engine.conf',
    }

  heat_engine_config {
    'DEFAULT/rabbit_userid'                                   : value => $rabbit_userid;
    'DEFAULT/rabbit_password'                                 : value => $rabbit_password;
    'DEFAULT/rabbit_virtualhost'                              : value => $rabbit_virtualhost;
    'DEFAULT/debug'                                           : value => $debug;
    'DEFAULT/verbose'                                         : value => $verbose;
    'DEFAULT/log_dir'                                         : value => $::heat::params::log_dir;
    'DEFAULT/bind_host'                                       : value => $bind_host;
    'DEFAULT/bind_port'                                       : value => $bind_port;
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
  }
}
