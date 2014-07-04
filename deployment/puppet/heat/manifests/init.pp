# Class heat
#
#  heat base package & configuration
#
# == parameters
#  [*package_ensure*]
#    ensure state for package. Optional. Defaults to 'present'
#  [*verbose*]
#    should the daemons log verbose messages. Optional. Defaults to 'False'
#  [*debug*]
#    should the daemons log debug messages. Optional. Defaults to 'False'
#
#  [*log_dir*]
#   (optional) Directory where logs should be stored.
#   If set to boolean false, it will not log to any directory.
#   Defaults to '/var/log/heat'.
#
#  [*rabbit_host*]
#    ip or hostname of the rabbit server. Optional. Defaults to '127.0.0.1'
#  [*rabbit_port*]
#    port of the rabbit server. Optional. Defaults to 5672.
#  [*rabbit_hosts*]
#    array of host:port (used with HA queues). Optional. Defaults to undef.
#    If defined, will remove rabbit_host & rabbit_port parameters from config
#  [*rabbit_userid*]
#    user to connect to the rabbit server. Optional. Defaults to 'guest'
#  [*rabbit_password*]
#    password to connect to the rabbit_server. Optional. Defaults to empty.
#  [*rabbit_virtual_host*]
#    virtual_host to use. Optional. Defaults to '/'
#  [*rabbit_use_ssl*]
#    (optional) Connect over SSL for RabbitMQ
#    Defaults to false
#  [*kombu_ssl_ca_certs*]
#    (optional) SSL certification authority file (valid only if SSL enabled).
#    Defaults to undef
#  [*kombu_ssl_certfile*]
#    (optional) SSL cert file (valid only if SSL enabled).
#    Defaults to undef
#  [*kombu_ssl_keyfile*]
#    (optional) SSL key file (valid only if SSL enabled).
#    Defaults to undef
#  [*kombu_ssl_version*]
#    (optional) SSL version to use (valid only if SSL enabled).
#    Valid values are TLSv1, SSLv23 and SSLv3. SSLv2 may be
#    available on some distributions.
#    Defaults to 'SSLv3'
#  [*amqp_durable_queues*]
#    Use durable queues in amqp. Defaults to false
#
#  (keystone authentication options)
#  [*auth_uri*]
#    Specifies the Authentication URI for Heat to use. Located in heat.conf
#    Optional. Defaults to false, which uses:
#    "${keystone_protocol}://${keystone_host}:5000/v2.0"
#  [*keystone_host*]
#  [*keystone_port*]
#  [*keystone_protocol*]
#  [*keystone_user*]
#  [*keystone_tenant*]
#  [*keystone_password*]
#  [*keystone_ec2_uri*]
#
#  (optional) various QPID options
#  [*qpid_hostname*]
#  [*qpid_port*]
#  [*qpid_username*]
#  [*qpid_password*]
#  [*qpid_heartbeat*]
#  [*qpid_protocol*]
#  [*qpid_tcp_nodelay*]
#  [*qpid_reconnect*]
#  [*qpid_reconnect_timeout*]
#  [*qpid_reconnect_limit*]
#  [*qpid_reconnect_interval*]
#  [*qpid_reconnect_interval_min*]
#  [*qpid_reconnect_interval_max*]
#
# [*database_idle_timeout*]
#   (optional) Timeout before idle db connections are reaped.
#   Defaults to 3600
#
# [*use_syslog*]
#   (optional) Use syslog for logging
#   Defaults to false
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines
#   Defaults to LOG_USER
#
# [*mysql_module*]
#   (optional) The mysql puppet module version.
#   Tested versions include 0.9 and 2.2
#   Defaults to '0.9'
#
class heat(
  $auth_uri                    = false,
  $package_ensure              = 'present',
  $verbose                     = false,
  $debug                       = false,
  $log_dir                     = '/var/log/heat',
  $keystone_host               = '127.0.0.1',
  $keystone_port               = '35357',
  $keystone_protocol           = 'http',
  $keystone_user               = 'heat',
  $keystone_tenant             = 'services',
  $keystone_password           = false,
  $keystone_ec2_uri            = 'http://127.0.0.1:5000/v2.0/ec2tokens',
  $rpc_backend                 = 'heat.openstack.common.rpc.impl_kombu',
  $rabbit_host                 = '127.0.0.1',
  $rabbit_port                 = 5672,
  $rabbit_hosts                = undef,
  $rabbit_userid               = 'guest',
  $rabbit_password             = '',
  $rabbit_virtual_host         = '/',
  $rabbit_use_ssl              = false,
  $kombu_ssl_ca_certs          = undef,
  $kombu_ssl_certfile          = undef,
  $kombu_ssl_keyfile           = undef,
  $kombu_ssl_version           = 'SSLv3',
  $amqp_durable_queues         = false,
  $qpid_hostname               = 'localhost',
  $qpid_port                   = 5672,
  $qpid_username               = 'guest',
  $qpid_password               = 'guest',
  $qpid_heartbeat              = 60,
  $qpid_protocol               = 'tcp',
  $qpid_tcp_nodelay            = true,
  $qpid_reconnect              = true,
  $qpid_reconnect_timeout      = 0,
  $qpid_reconnect_limit        = 0,
  $qpid_reconnect_interval_min = 0,
  $qpid_reconnect_interval_max = 0,
  $qpid_reconnect_interval     = 0,
  $sql_connection              = false,
  $database_idle_timeout       = 3600,
  $use_syslog                  = false,
  $log_facility                = 'LOG_USER',
  $mysql_module                = '0.9',
) {

  include heat::params

  File {
    require => Package['heat-common'],
  }

  group { 'heat':
    name    => 'heat',
    require => Package['heat-common'],
  }

  user { 'heat':
    name    => 'heat',
    gid     => 'heat',
    groups  => ['heat'],
    system  => true,
    require => Package['heat-common'],
  }

  file { '/etc/heat/':
    ensure  => directory,
    owner   => 'heat',
    group   => 'heat',
    mode    => '0750',
  }

  file { '/etc/heat/heat.conf':
    owner   => 'heat',
    group   => 'heat',
    mode    => '0640',
  }

  package { 'heat-common':
    ensure => $package_ensure,
    name   => $::heat::params::common_package_name,
  }

  Package['heat-common'] -> Heat_config<||>

  if $rpc_backend == 'heat.openstack.common.rpc.impl_kombu' {

    if $rabbit_hosts {
      heat_config { 'DEFAULT/rabbit_host': ensure => absent }
      heat_config { 'DEFAULT/rabbit_port': ensure => absent }
      heat_config { 'DEFAULT/rabbit_hosts':
        value => join($rabbit_hosts, ',')
      }
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

    heat_config {
      'DEFAULT/rabbit_userid'          : value => $rabbit_userid;
      'DEFAULT/rabbit_password'        : value => $rabbit_password;
      'DEFAULT/rabbit_virtual_host'    : value => $rabbit_virtual_host;
      'DEFAULT/rabbit_use_ssl'         : value => $rabbit_use_ssl;
      'DEFAULT/amqp_durable_queues'    : value => $amqp_durable_queues;
    }

    if $rabbit_use_ssl {
      heat_config { 'DEFAULT/kombu_ssl_version': value => $kombu_ssl_version }

      if $kombu_ssl_ca_certs {
        heat_config { 'DEFAULT/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs }
      } else {
        heat_config { 'DEFAULT/kombu_ssl_ca_certs': ensure => absent}
      }

      if $kombu_ssl_certfile {
        heat_config { 'DEFAULT/kombu_ssl_certfile': value => $kombu_ssl_certfile }
      } else {
        heat_config { 'DEFAULT/kombu_ssl_certfile': ensure => absent}
      }

      if $kombu_ssl_keyfile {
        heat_config { 'DEFAULT/kombu_ssl_keyfile': value => $kombu_ssl_keyfile }
      } else {
        heat_config { 'DEFAULT/kombu_ssl_keyfile': ensure => absent}
      }
    } else {
      heat_config {
        'DEFAULT/kombu_ssl_version':  ensure => absent;
        'DEFAULT/kombu_ssl_ca_certs': ensure => absent;
        'DEFAULT/kombu_ssl_certfile': ensure => absent;
        'DEFAULT/kombu_ssl_keyfile':  ensure => absent;
      }
      if ($kombu_ssl_keyfile or $kombu_ssl_certfile or $kombu_ssl_ca_certs) {
        notice('Configuration of certificates with $rabbit_use_ssl == false is a useless config')
      }
    }
  }

  if $rpc_backend == 'heat.openstack.common.rpc.impl_qpid' {

    heat_config {
      'DEFAULT/qpid_hostname'               : value => $qpid_hostname;
      'DEFAULT/qpid_port'                   : value => $qpid_port;
      'DEFAULT/qpid_username'               : value => $qpid_username;
      'DEFAULT/qpid_password'               : value => $qpid_password;
      'DEFAULT/qpid_heartbeat'              : value => $qpid_heartbeat;
      'DEFAULT/qpid_protocol'               : value => $qpid_protocol;
      'DEFAULT/qpid_tcp_nodelay'            : value => $qpid_tcp_nodelay;
      'DEFAULT/qpid_reconnect'              : value => $qpid_reconnect;
      'DEFAULT/qpid_reconnect_timeout'      : value => $qpid_reconnect_timeout;
      'DEFAULT/qpid_reconnect_limit'        : value => $qpid_reconnect_limit;
      'DEFAULT/qpid_reconnect_interval_min' : value => $qpid_reconnect_interval_min;
      'DEFAULT/qpid_reconnect_interval_max' : value => $qpid_reconnect_interval_max;
      'DEFAULT/qpid_reconnect_interval'     : value => $qpid_reconnect_interval;
      'DEFAULT/amqp_durable_queues'         : value => $amqp_durable_queues;
    }

  }

  if $auth_uri {
    heat_config { 'keystone_authtoken/auth_uri': value => $auth_uri; }
  } else {
    heat_config { 'keystone_authtoken/auth_uri': value => "${keystone_protocol}://${keystone_host}:5000/v2.0"; }
  }

  heat_config {
    'DEFAULT/rpc_backend'                  : value => $rpc_backend;
    'DEFAULT/debug'                        : value => $debug;
    'DEFAULT/verbose'                      : value => $verbose;
    'ec2authtoken/auth_uri'                : value => $keystone_ec2_uri;
    'keystone_authtoken/auth_host'         : value => $keystone_host;
    'keystone_authtoken/auth_port'         : value => $keystone_port;
    'keystone_authtoken/auth_protocol'     : value => $keystone_protocol;
    'keystone_authtoken/admin_tenant_name' : value => $keystone_tenant;
    'keystone_authtoken/admin_user'        : value => $keystone_user;
    'keystone_authtoken/admin_password'    : value => $keystone_password;
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

  if $sql_connection {

    validate_re($sql_connection,
      '(sqlite|mysql|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')

    case $sql_connection {
      /^mysql:\/\//: {
        $backend_package = false
        if ($mysql_module >= 2.2) {
          require mysql::bindings
          require mysql::bindings::python
        } else {
          include mysql::python
        }
      }
      /^postgresql:\/\//: {
        $backend_package = 'python-psycopg2'
      }
      /^sqlite:\/\//: {
        $backend_package = 'python-pysqlite2'
      }
      default: {
        fail('Unsupported backend configured')
      }
    }

    if $backend_package and !defined(Package[$backend_package]) {
      package {'heat-backend-package':
        ensure => present,
        name   => $backend_package,
      }
    }

    heat_config {
      'database/connection': value => $sql_connection;
      'database/idle_timeout':  value => $database_idle_timeout;
    }

    Heat_config['database/connection'] ~> Exec['heat-dbsync']

    exec { 'heat-dbsync':
      command     => $::heat::params::dbsync_command,
      path        => '/usr/bin',
      user        => 'heat',
      refreshonly => true,
      logoutput   => on_failure,
    }
  }

  # Syslog configuration
  if $use_syslog {
    heat_config {
      'DEFAULT/use_syslog':           value => true;
      'DEFAULT/syslog_log_facility':  value => $log_facility;
    }
  } else {
    heat_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

}
