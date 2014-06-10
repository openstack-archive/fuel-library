# Class ceilometer
#
#  ceilometer base package & configuration
#
# == parameters
#  [*metering_secret*]
#    secret key for signing messages. Mandatory.
#  [*package_ensure*]
#    ensure state for package. Optional. Defaults to 'present'
#  [*verbose*]
#    should the daemons log verbose messages. Optional. Defaults to false
#  [*debug*]
#    should the daemons log debug messages. Optional. Defaults to false
#  [*log_dir*]
#   (optional) directory to which ceilometer logs are sent.
#   If set to boolean false, it will not log to any directory.
#   Defaults to '/var/log/ceilometer'
#  [*use_syslog*]
#   (optional) Use syslog for logging
#   Defaults to false
#  [*syslog_log_facility*]
#   (optional) Syslog facility to receive log lines.
#   Defaults to 'LOG_LOCAL0'
#  [*amqp_hosts*]
#    AMQP servers connection string. Optional. Defaults to '127.0.0.1'
#  [*amqp_user*]
#    user to connect to the AMQP server. Optional. Defaults to 'guest'
#  [*amqp_password*]
#    password to connect to the amqp_hosts. Optional. Defaults to 'rabbit_pw'.
#  [*rabbit_ha_queues*]
#    create mirrored queues. Optional. Defaults to false
#  [*rabbit_virtual_host*]
#    virtualhost to use. Optional. Defaults to '/'
#
class ceilometer(
  $metering_secret     = false,
  $package_ensure      = 'present',
  $verbose             = false,
  $debug               = false,
  $log_dir             = '/var/log/ceilometer',
  $use_syslog          = false,
  $syslog_log_facility = 'LOG_LOCAL0',
  $queue_provider      = 'rabbitmq',
  $amqp_hosts          = '127.0.0.1',
  $amqp_user           =  'guest',
  $amqp_password       = 'rabbit_pw',
  $rabbit_ha_queues    = false,
  $rabbit_virtual_host = '/',
) {

  validate_string($metering_secret)

  include ceilometer::params

  File {
    require => Package['ceilometer-common'],
  }

  group { 'ceilometer':
    name    => 'ceilometer',
    require => Package['ceilometer-common'],
  }

  user { 'ceilometer':
    name    => 'ceilometer',
    gid     => 'ceilometer',
    groups  => ['nova'],
    system  => true,
    require => Package['ceilometer-common'],
  }

  file { '/etc/ceilometer/':
    ensure  => directory,
    owner   => 'ceilometer',
    group   => 'ceilometer',
    mode    => '0750',
  }

  file { '/etc/ceilometer/ceilometer.conf':
    owner   => 'ceilometer',
    group   => 'ceilometer',
    mode    => '0640',
  }

  package { 'ceilometer-common':
    ensure => $package_ensure,
    name   => $::ceilometer::params::common_package_name,
  }

  Package['ceilometer-common'] -> Ceilometer_config<||>

  # Configure RPC
  case $queue_provider {
    'rabbitmq': {
      ceilometer_config {
        'DEFAULT/rabbit_hosts':        value => $amqp_hosts;
        'DEFAULT/rabbit_userid':       value => $amqp_user;
        'DEFAULT/rabbit_password':     value => $amqp_password;
        'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
        'DEFAULT/rabbit_ha_queues':    value => $rabbit_ha_queues;
        'DEFAULT/kombu_reconnect_delay':   value       => '5.0';
        'DEFAULT/rpc_backend':
          value => 'ceilometer.openstack.common.rpc.impl_kombu';
      }
    }

    'qpid': {
      ceilometer_config {
        'DEFAULT/qpid_hosts':    value => $amqp_hosts;
        'DEFAULT/qpid_username': value => $amqp_user;
        'DEFAULT/qpid_password': value => $amqp_password;
        'DEFAULT/rpc_backend':
          value => 'ceilometer.openstack.common.rpc.impl_qpid';
      }
    }
  }

  ceilometer_config {
    'publisher_rpc/metering_secret'  : value => $metering_secret;
    'DEFAULT/debug'                  : value => $debug;
    'DEFAULT/verbose'                : value => $verbose;
  }

 # Log configuration
  if $log_dir {
    ceilometer_config {
      'DEFAULT/log_dir' : value => $log_dir;
    }
  } else {
    ceilometer_config {
      'DEFAULT/log_dir' : ensure => absent;
    }
  }

  # Syslog configuration
  if $use_syslog {
    ceilometer_config {
      'DEFAULT/use_syslog':            value => true;
      'DEFAULT/use_syslog_rfc_format': value => true;
      'DEFAULT/syslog_log_facility':   value => $syslog_log_facility;
    }
  } else {
    ceilometer_config {
      'DEFAULT/use_syslog': value => false;
    }
  }
}
