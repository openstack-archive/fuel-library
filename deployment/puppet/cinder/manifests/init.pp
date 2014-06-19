#
# == Parameters
# [database_connection]
#    Url used to connect to database.
#    (Optional) Defaults to
#    'sqlite:////var/lib/cinder/cinder.sqlite'
#
# [database_idle_timeout]
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
# [sql_connection]
#   DEPRECATED
# [sql_idle_timeout]
#   DEPRECATED
#
class cinder (
  $database_connection         = 'sqlite:////var/lib/cinder/cinder.sqlite',
  $database_idle_timeout       = '3600',
  $rpc_backend                 = 'cinder.openstack.common.rpc.impl_kombu',
  $control_exchange            = 'openstack',
  $rabbit_host                 = '127.0.0.1',
  $rabbit_port                 = 5672,
  $rabbit_hosts                = false,
  $rabbit_virtual_host         = '/',
  $rabbit_userid               = 'guest',
  $rabbit_password             = false,
  $amqp_durable_queues         = false,
  $qpid_hostname               = 'localhost',
  $qpid_port                   = '5672',
  $qpid_username               = 'guest',
  $qpid_password               = false,
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
  $log_facility                = 'LOG_USER',
  $log_dir                     = '/var/log/cinder',
  $verbose                     = false,
  $debug                       = false,
  $mysql_module                = '0.9',
  # DEPRECATED PARAMETERS
  $sql_connection              = undef,
  $sql_idle_timeout            = undef,
) {

  include cinder::params

  Package['cinder'] -> Cinder_config<||>
  Package['cinder'] -> Cinder_api_paste_ini<||>

  if $sql_connection {
    warning('The sql_connection parameter is deprecated, use database_connection instead.')
    $database_connection_real = $sql_connection
  } else {
    $database_connection_real = $database_connection
  }

  if $sql_idle_timeout {
    warning('The sql_idle_timeout parameter is deprecated, use database_idle_timeout instead.')
    $database_idle_timeout_real = $sql_idle_timeout
  } else {
    $database_idle_timeout_real = $database_idle_timeout
  }

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

  if $rpc_backend == 'cinder.openstack.common.rpc.impl_kombu' {

    if ! $rabbit_password {
      fail('Please specify a rabbit_password parameter.')
    }

    cinder_config {
      'DEFAULT/rabbit_password':     value => $rabbit_password, secret => true;
      'DEFAULT/rabbit_userid':       value => $rabbit_userid;
      'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
      'DEFAULT/control_exchange':    value => $control_exchange;
      'DEFAULT/amqp_durable_queues': value => $amqp_durable_queues;
    }

    if $rabbit_hosts {
      cinder_config { 'DEFAULT/rabbit_hosts':     value => join($rabbit_hosts, ',') }
      cinder_config { 'DEFAULT/rabbit_ha_queues': value => true }
    } else {
      cinder_config { 'DEFAULT/rabbit_host':      value => $rabbit_host }
      cinder_config { 'DEFAULT/rabbit_port':      value => $rabbit_port }
      cinder_config { 'DEFAULT/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}" }
      cinder_config { 'DEFAULT/rabbit_ha_queues': value => false }
    }
  }

  if $rpc_backend == 'cinder.openstack.common.rpc.impl_qpid' {

    if ! $qpid_password {
      fail('Please specify a qpid_password parameter.')
    }

    cinder_config {
      'DEFAULT/qpid_hostname':               value => $qpid_hostname;
      'DEFAULT/qpid_port':                   value => $qpid_port;
      'DEFAULT/qpid_username':               value => $qpid_username;
      'DEFAULT/qpid_password':               value => $qpid_password, secret => true;
      'DEFAULT/qpid_reconnect':              value => $qpid_reconnect;
      'DEFAULT/qpid_reconnect_timeout':      value => $qpid_reconnect_timeout;
      'DEFAULT/qpid_reconnect_limit':        value => $qpid_reconnect_limit;
      'DEFAULT/qpid_reconnect_interval_min': value => $qpid_reconnect_interval_min;
      'DEFAULT/qpid_reconnect_interval_max': value => $qpid_reconnect_interval_max;
      'DEFAULT/qpid_reconnect_interval':     value => $qpid_reconnect_interval;
      'DEFAULT/qpid_heartbeat':              value => $qpid_heartbeat;
      'DEFAULT/qpid_protocol':               value => $qpid_protocol;
      'DEFAULT/qpid_tcp_nodelay':            value => $qpid_tcp_nodelay;
      'DEFAULT/amqp_durable_queues':         value => $amqp_durable_queues;
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

  cinder_config {
    'database/connection':         value => $database_connection_real, secret => true;
    'database/idle_timeout':       value => $database_idle_timeout_real;
    'DEFAULT/verbose':             value => $verbose;
    'DEFAULT/debug':               value => $debug;
    'DEFAULT/api_paste_config':    value => $api_paste_config;
    'DEFAULT/rpc_backend':         value => $rpc_backend;
  }

  if($database_connection_real =~ /mysql:\/\/\S+:\S+@\S+\/\S+/) {
    if ($mysql_module >= 2.2) {
      require 'mysql::bindings'
      require 'mysql::bindings::python'
    } else {
      require 'mysql::python'
    }
  } elsif($database_connection_real =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

  } elsif($database_connection_real =~ /sqlite:\/\//) {

  } else {
    fail("Invalid db connection ${database_connection_real}")
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
      'DEFAULT/use_syslog':           value => true;
      'DEFAULT/syslog_log_facility':  value => $log_facility;
    }
  } else {
    cinder_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

}
