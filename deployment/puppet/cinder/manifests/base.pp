#
# parameters that may need to be added
# $state_path = /opt/stack/data/cinder
# $osapi_volume_extension = cinder.api.openstack.volume.contrib.standard_extensions
# $root_helper = sudo /usr/local/bin/cinder-rootwrap /etc/cinder/rootwrap.conf
# [*use_syslog*]
#   Use syslog for logging.
#   (Optional) Defaults to false.
#
# [*syslog_log_facility*]
#   Syslog facility to receive log lines.
#   (Optional) Defaults to LOG_LOCAL3.
#
# [*log_dir*]
#   (optional) Directory where logs should be stored.
#   If set to boolean false, it will not log to any directory.
#   Defaults to '/var/log/cinder'
#

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

  if $log_dir {
    cinder_config {
      'DEFAULT/log_dir': value => $log_dir;
    }
  } else {
    cinder_config {
      'DEFAULT/log_dir': ensure => absent;
    }
  }

  if $use_syslog {
    cinder_config {
      'DEFAULT/use_syslog':            value => true;
      'DEFAULT/use_syslog_rfc_format': value => true;
      'DEFAULT/syslog_log_facility':   value => $syslog_log_facility;
    }
  } else {
    cinder_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

  Cinder_config<||> -> Exec['cinder-manage db_sync']
  Nova_config<||> -> Exec['cinder-manage db_sync']
  Cinder_api_paste_ini<||> -> Exec['cinder-manage db_sync']
  Exec['cinder-manage db_sync'] -> Service<| title == $::cinder::params::api_service |>
  Exec['cinder-manage db_sync'] -> Service<| title == $::cinder::params::volume_service |>
  Exec['cinder-manage db_sync'] -> Service<| title == $::cinder::params::scheduler_service |>
}
