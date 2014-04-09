#
# == Parameters
#
# [sql_idle_timeout]
#   Timeout when db connections should be reaped.
#   (Optional) Defaults to 3600.
#
# [amqp_durable_queues]
#   Use durable queues in amqp.
#   (Optional) Defaults to false.
#
# [use_syslog]
#   Use syslog for logging.
#   (Optional) Defaults to false.
#
# [log_facility]
#   Syslog facility to receive log lines.
#   (Optional) Defaults to LOG_USER.
#
# [*log_dir*]
#   (optional) Directory where logs should be stored.
#   If set to boolean false, it will not log to any directory.
#   Defaults to '/var/log/cinder'
#
# [*mysql_module*]
#   (optional) Puppetlabs-mysql module version to use
#   Tested versions include 0.9 and 2.2
#   Defaults to '0.9'
#
class cinder (
  $sql_connection,
  $sql_idle_timeout            = '3600',
  $rpc_backend                 = 'cinder.openstack.common.rpc.impl_kombu',
  $control_exchange            = 'openstack',
  $queue_provider              = 'rabbitmq',
  $amqp_hosts                  = '127.0.0.1',
  $amqp_user                   = 'nova',
  $amqp_password               = 'rabbit_pw',
  $rabbit_virtual_host         = '/',
  $rabbit_userid               = 'guest',
  $rabbit_password             = false,
  $amqp_durable_queues         = false,
  $qpid_sasl_mechanisms        = false,
  $qpid_reconnect              = true,
  $qpid_reconnect_timeout      = 0,
  $qpid_reconnect_limit        = 0,
  $qpid_reconnect_interval_min = 0,
  $qpid_reconnect_interval_max = 0,
  $qpid_reconnect_interval     = 0,
  $qpid_heartbeat              = 60,
  $qpid_protocol               = 'tcp',
  $qpid_tcp_nodelay            = true,
  $package_ensure              = 'present',
  $api_paste_config            = '/etc/cinder/api-paste.ini',
  $use_syslog                  = false,
  $syslog_log_facility         = 'LOG_LOCAL3',
  $syslog_log_level            = 'WARNING',
  $log_dir                     = '/var/log/cinder',
  $idle_timeout                = '3600',
  $max_pool_size               = '10',
  $max_overflow                = '30',
  $max_retries                 = '-1',
  $verbose                     = false,
  $debug                       = false,
  $mysql_module                = '0.9'
) {

  include cinder::params

  Package['cinder'] -> Cinder_config<||>
  Package['cinder'] -> Cinder_api_paste_ini<||>

  # this anchor is used to simplify the graph between cinder components by
  # allowing a resource to serve as a point where the configuration of cinder begins
  anchor { 'cinder-start': }

  package { 'cinder':
    ensure  => $package_ensure,
    name    => $::cinder::params::package_name,
    require => Anchor['cinder-start'],
  }

  file { $::cinder::params::cinder_conf:
    ensure  => present,
    owner   => 'cinder',
    group   => 'cinder',
    mode    => '0600',
    require => Package['cinder'],
  }

  file { $::cinder::params::cinder_paste_api_ini:
    ensure  => present,
    owner   => 'cinder',
    group   => 'cinder',
    mode    => '0600',
    require => Package['cinder'],
  }

  if ! $amqp_password {
    fail('Please specify an amqp_password parameter.')
  }

  # turn on rabbitmq ha/cluster mode
  if $queue_provider == 'rabbitmq' and is_array($amqp_hosts) {
    if size($amqp_hosts) > 1 {
      cinder_config { 'DEFAULT/rabbit_ha_queues': value => true }
    } else {
      cinder_config { 'DEFAULT/rabbit_ha_queues': value => false }
    }
  }

  case $queue_provider {
    'rabbitmq': {
      cinder_config {
        'DEFAULT/rpc_backend':         value => 'cinder.openstack.common.rpc.impl_kombu';
        'DEFAULT/rabbit_hosts':        value => $amqp_hosts;
        'DEFAULT/rabbit_userid':       value => $amqp_user;
        'DEFAULT/rabbit_password':     value => $amqp_password;
        'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
      }
    }
    'qpid': {
      cinder_config {
        'DEFAULT/rpc_backend':         value => 'cinder.openstack.common.rpc.impl_qpid';
        'DEFAULT/qpid_hosts':                  value => $amqp_hosts;
        'DEFAULT/qpid_username':               value => $amqp_user;
        'DEFAULT/qpid_password':               value => $amqp_password;
        'DEFAULT/control_exchange':            value => $control_exchange;
        'DEFAULT/amqp_durable_queues':         value => $amqp_durable_queues;
        'DEFAULT/qpid_reconnect':              value => $qpid_reconnect;
        'DEFAULT/qpid_reconnect_timeout':      value => $qpid_reconnect_timeout;
        'DEFAULT/qpid_reconnect_limit':        value => $qpid_reconnect_limit;
        'DEFAULT/qpid_reconnect_interval_min': value => $qpid_reconnect_interval_min;
        'DEFAULT/qpid_reconnect_interval_max': value => $qpid_reconnect_interval_max;
        'DEFAULT/qpid_reconnect_interval':     value => $qpid_reconnect_interval;
        'DEFAULT/qpid_heartbeat':              value => $qpid_heartbeat;
        'DEFAULT/qpid_protocol':               value => $qpid_protocol;
        'DEFAULT/qpid_tcp_nodelay':            value => $qpid_tcp_nodelay;
      }
      if is_array($qpid_sasl_mechanisms) {
        cinder_config {
          'DEFAULT/qpid_sasl_mechanisms': value => join($qpid_sasl_mechanisms, ' ');
        }
      } elsif $qpid_sasl_mechanisms {
        cinder_config {
          'DEFAULT/qpid_sasl_mechanisms': value => $qpid_sasl_mechanisms;
        }
      } else {
        cinder_config {
          'DEFAULT/qpid_sasl_mechanisms': ensure => absent;
        }
      }
    }
  }

  cinder_config {
    'DATABASE/connection':         value => $sql_connection, secret => true;
    'DATABASE/max_pool_size':      value => $max_pool_size;
    'DATABASE/max_retries':        value => $max_retries;
    'DATABASE/max_overflow':       value => $max_overflow;
    'DATABASE/idle_timeout':       value => $idle_timeout;
    'DEFAULT/verbose':             value => $verbose;
    'DEFAULT/debug':               value => $debug;
    'DEFAULT/api_paste_config':    value => $api_paste_config;
  }

  if $mysql_module >= 2.2 {
    require mysql::bindings
    require mysql::bindings::python
  } else {
    require mysql::python
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
      'DEFAULT/use_syslog': value =>  false;
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
  }
}
