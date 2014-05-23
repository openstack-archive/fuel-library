#
# parameters that may need to be added
# $state_path = /opt/stack/data/cinder
# $osapi_volume_extension = cinder.api.openstack.volume.contrib.standard_extensions
# $root_helper = sudo /usr/local/bin/cinder-rootwrap /etc/cinder/rootwrap.conf
# $use_syslog = Rather or not service should log to syslog. Optional.
# $syslog_log_facility = Facility for syslog, if used. Optional.
# $syslog_log_level = logging level for non verbose and non debug mode. Optional.

class cinder::base (
  $sql_connection,
  $queue_provider         = 'rabbitmq',
  $amqp_hosts             = '127.0.0.1',
  $amqp_user              = 'nova',
  $amqp_password          = 'rabbit_pw',
  $rabbit_virtual_host    = '/',
  $package_ensure         = 'present',
  $verbose                = false,
  $debug                  = false,
  $use_syslog             = false,
  $syslog_log_facility    = 'LOG_LOCAL3',
  $syslog_log_level = 'WARNING',
  $log_dir                = '/var/log/cinder',
  $idle_timeout           = '3600',
  $max_pool_size          = '10',
  $max_overflow           = '30',
  $max_retries            = '-1',
) {

  include cinder::params

  if !defined(Package[$::cinder::params::qemuimg_package_name])
  {
    package {"$::cinder::params::qemuimg_package_name":}
  }

  package { 'python-cinder':
        ensure  => $package_ensure,
         }
  Package['cinder'] -> Cinder_config<||>
  Package['cinder'] -> Cinder_api_paste_ini<||>

  package { 'cinder':
    name => $::cinder::params::package_name,
    ensure => $package_ensure,
  }

  File {
    ensure  => present,
    owner   => 'cinder',
    group   => 'cinder',
    mode    => '0640',
    require => Package['cinder'],
  }

  if $use_syslog and !$debug { #syslog and nondebug case
    cinder_config {
      'DEFAULT/log_config': value => "/etc/cinder/logging.conf";
      'DEFAULT/use_syslog': value => true;
      'DEFAULT/syslog_log_facility': value =>  $syslog_log_facility;
    }
    file { "cinder-logging.conf":
      content => template('cinder/logging.conf.erb'),
      path => "/etc/cinder/logging.conf",
      require => File[$::cinder::params::cinder_conf],
    }
    # We must notify services to apply new logging rules
    File['cinder-logging.conf'] ~> Service <| title == 'cinder-api' |>
    File['cinder-logging.conf'] ~> Service <| title == 'cinder-volume' |>
    File['cinder-logging.conf'] ~> Service <| title == 'cinder-scheduler' |>
  } else { #other syslog debug or nonsyslog debug/nondebug cases
    cinder_config {
      'DEFAULT/log_config': ensure=> absent;
      'DEFAULT/logdir': value=> $log_dir;
      'DEFAULT/use_syslog': value =>  false;
    }
  }

  file { $::cinder::params::cinder_conf: }
  file { $::cinder::params::cinder_paste_api_ini: }

  # Temporary fixes
  file { ['/var/log/cinder', '/var/lib/cinder']:
    ensure => directory,
    owner  => 'cinder',
    group  => 'cinder',
  }

  case $queue_provider {
    'rabbitmq': {
      cinder_config {
        'DEFAULT/rpc_backend':           value => 'cinder.openstack.common.rpc.impl_kombu';
        'DEFAULT/rabbit_hosts':          value => $amqp_hosts;
        'DEFAULT/rabbit_userid':         value => $amqp_user;
        'DEFAULT/rabbit_password':       value => $amqp_password;
        'DEFAULT/rabbit_virtual_host':   value => $rabbit_virtual_host;
        'DEFAULT/kombu_reconnect_delay': value => '5.0';
      }
    }
    'qpid': {
      cinder_config {
        'DEFAULT/rpc_backend':   value => 'cinder.openstack.common.rpc.impl_qpid';
        'DEFAULT/qpid_hosts':    value => $amqp_hosts;
        'DEFAULT/qpid_username': value => $amqp_user;
        'DEFAULT/qpid_password': value => $amqp_password;
      }
    }
  }

  cinder_config {
    'DATABASE/connection':         value => $sql_connection;
    'DEFAULT/debug':               value => $debug;
    'DEFAULT/verbose':             value => $verbose;
    'DEFAULT/api_paste_config':    value => '/etc/cinder/api-paste.ini';
    'DEFAULT/control_exchange':    value => 'cinder';
    'DEFAULT/notification_driver': value => 'cinder.openstack.common.notifier.rpc_notifier';
  }

  cinder_config {
    'DATABASE/max_pool_size': value => $max_pool_size;
    'DATABASE/max_retries':   value => $max_retries;
    'DATABASE/max_overflow':  value => $max_overflow;
    'DATABASE/idle_timeout':  value => $idle_timeout;
  }
  exec { 'cinder-manage db_sync':
    command     => $::cinder::params::db_sync_command,
    path        => '/usr/bin',
    user        => 'cinder',
    refreshonly => true,
    logoutput   => 'on_failure',
    tries       => 10,
    try_sleep   => 3,
  }
  Cinder_config<||> -> Exec['cinder-manage db_sync']
  Nova_config<||> -> Exec['cinder-manage db_sync']
  Cinder_api_paste_ini<||> -> Exec['cinder-manage db_sync']
 Exec['cinder-manage db_sync'] -> Service<| title == $::cinder::params::api_service |>
 Exec['cinder-manage db_sync'] -> Service<| title == $::cinder::params::volume_service |>
 Exec['cinder-manage db_sync'] -> Service<| title == $::cinder::params::scheduler_service |>
}
