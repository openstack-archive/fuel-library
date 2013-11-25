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
#    should the daemons log verbose messages. Optional. Defaults to 'False'
#  [*debug*]
#    should the daemons log debug messages. Optional. Defaults to 'False'
#  [*rabbit_host*]
#    ip or hostname of the rabbit server. Optional. Defaults to '127.0.0.1'
#  [*rabbit_port*]
#    port of the rabbit server. Optional. Defaults to 5672.
#  [*rabbit_userid*]
#    user to connect to the rabbit server. Optional. Defaults to 'guest'
#  [*rabbit_password*]
#    password to connect to the rabbit_server. Optional. Defaults to empty.
#  [*rabbit_virtual_host*]
#    virtualhost to use. Optional. Defaults to '/'
#  [*qpid_host*]
#    ip or hostname of the qpid server. Optional. Defaults to '127.0.0.1'
#  [*qpid_nodes*]
#    list of ips or hostnames of the qpid servers. Optional. Defaults to false.
#  [*qpid_port*]
#    port of the qpid server. Optional. Defaults to 5672.
#  [*qpid_userid*]
#    user to connect to the qpid server. Optional. Defaults to 'nova'
#  [*qpid_password*]
#    password to connect to the qpid_server. Optional. Defaults to 'qpid_pw'.
#
class ceilometer(
  $metering_secret     = false,
  $package_ensure      = 'present',
  $verbose             = 'False',
  $debug               = 'False',
  $use_syslog          = false,
  $syslog_log_facility = 'SYSLOG',
  $syslog_log_level    = 'WARNING',
  $queue_provider      = 'rabbitmq',
  $rabbit_host         = '127.0.0.1',
  $rabbit_port         = 5672,
  $rabbit_userid       = 'guest',
  $rabbit_password     = '',
  $rabbit_virtual_host = '/',
  $qpid_host           = '127.0.0.1',
  $qpid_nodes          = false,
  $qpid_port           = 5672,
  $qpid_userid         = 'nova',
  $qpid_password       = 'qpid_pw',
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
        'DEFAULT/rabbit_userid'      : value => $rabbit_userid;
        'DEFAULT/rabbit_password'    : value => $rabbit_password;
        'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
        'DEFAULT/rabbit_ha_queues'   : value => true;
        'DEFAULT/rabbit_hosts'       : value => "${rabbit_host}:${rabbit_port}";
        'DEFAULT/rpc_backend':
          value => 'ceilometer.openstack.common.rpc.impl_kombu';
      }
    }

    'qpid': {
      ceilometer_config {
        'DEFAULT/qpid_username': value => $qpid_userid;
        'DEFAULT/qpid_password': value => $qpid_password;
        'DEFAULT/rpc_backend':
          value => 'ceilometer.openstack.common.rpc.impl_qpid';
      }
      if $qpid_nodes {
        ceilometer_config { 'DEFAULT/qpid_hosts':
          value => is_ip_address($qpid_nodes) ? {
                     true  => "${qpid_nodes}:${qpid_port}",
                     false => join($qpid_nodes, ','),
                   }
        }
      } else {
        ceilometer_config {
          'DEFAULT/qpid_hostname': value => $qpid_host;
          'DEFAULT/qpid_port'    : value => $qpid_port;
        }
      }
    }
  }

  ceilometer_config {
    'publisher_rpc/metering_secret'  : value => $metering_secret;
    'DEFAULT/debug'                  : value => $debug;
    'DEFAULT/verbose'                : value => $verbose;
  }

  # Configure logging
  if $use_syslog and !$debug =~ /(?i)(true|yes)/ {
    File['ceilometer-logging.conf'] -> Ceilometer_config['DEFAULT/log_config']
    ceilometer_config {
      'DEFAULT/log_config'         : value => '/etc/ceilometer/logging.conf';
      'DEFAULT/log_file'           : ensure => absent;
      'DEFAULT/log_dir'            : ensure => absent;
      'DEFAULT/use_stderr'         : ensure => absent;
      'DEFAULT/use_syslog'         : value => true;
      'DEFAULT/syslog_log_facility': value => $syslog_log_facility;
    }
    file { 'ceilometer-logging.conf':
      content => template('ceilometer/logging.conf.erb'),
      path    => '/etc/ceilometer/logging.conf',
    }
  }
  else {
    ceilometer_config {
      'DEFAULT/log_config': ensure=> absent;
      'DEFAULT/use_syslog': ensure=> absent;
      'DEFAULT/syslog_log_facility': ensure=> absent;
      'DEFAULT/use_stderr': ensure=> absent;
      'DEFAULT/log_dir': value => $::ceilometer::params::log_dir;
      'DEFAULT/logging_context_format_string':
       value => '%(asctime)s %(levelname)s %(name)s [%(request_id)s %(user_id)s %(project_id)s] %(instance)s %(message)s';
      'DEFAULT/logging_default_format_string':
       value => '%(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s';
    }
    # might be used for stdout logging instead, if configured
    file { 'ceilometer-logging.conf':
      content => template('ceilometer/logging.conf-nosyslog.erb'),
      path    => '/etc/ceilometer/logging.conf',
    }
  }

  # We must notify services to apply new logging rules
  File['ceilometer-logging.conf'] ~> Service<| title == "$::ceilometer::params::api_service_name" |>
  File['ceilometer-logging.conf'] ~> Service<| title == "$::ceilometer::params::collector_service_name" |>
  File['ceilometer-logging.conf'] ~> Service<| title == "$::ceilometer::params::agent_central_service_name" |>
  File['ceilometer-logging.conf'] ~> Service<| title == "$::ceilometer::params::agent_compute_service_name" |>

}
