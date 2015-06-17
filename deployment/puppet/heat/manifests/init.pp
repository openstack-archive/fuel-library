# == Class: heat
#
#  Heat base package & configuration
#
# === Parameters
#
# [*package_ensure*]
#    (Optional) Ensure state for package.
#    Defaults to 'present'
#
# [*verbose*]
#   (Optional) Should the daemons log verbose messages
#   Defaults to 'false'
#
# [*debug*]
#   (Optional) Should the daemons log debug messages
#   Defaults to 'false'
#
# [*log_dir*]
#   (Optional) Directory where logs should be stored
#   If set to boolean 'false', it will not log to any directory
#   Defaults to '/var/log/heat'
#
# [*rpc_backend*]
#   (Optional) Use these options to configure the RabbitMQ message system.
#   Defaults to 'heat.openstack.common.rpc.impl_kombu'
#
# [*rabbit_host*]
#   (Optional) IP or hostname of the rabbit server.
#   Defaults to '127.0.0.1'
#
# [*rabbit_port*]
#   (Optional) Port of the rabbit server.
#   Defaults to 5672.
#
# [*rabbit_hosts*]
#   (Optional) Array of host:port (used with HA queues).
#   If defined, will remove rabbit_host & rabbit_port parameters from config
#   Defaults to undef.
#
# [*rabbit_userid*]
#   (Optional) User to connect to the rabbit server.
#   Defaults to 'guest'
#
# [*rabbit_password*]
#   (Optional) Password to connect to the rabbit_server.
#   Defaults to empty.
#
# [*rabbit_virtual_host*]
#   (Optional) Virtual_host to use.
#   Defaults to '/'
#
# [*rabbit_use_ssl*]
#   (Optional) Connect over SSL for RabbitMQ.
#   Defaults to false
#
# [*kombu_ssl_ca_certs*]
#   (Optional) SSL certification authority file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_certfile*]
#   (Optional) SSL cert file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_keyfile*]
#   (Optional) SSL key file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_version*]
#   (Optional) SSL version to use (valid only if SSL enabled).
#   Valid values are TLSv1, SSLv23 and SSLv3. SSLv2 may be
#   available on some distributions.
#   Defaults to 'SSLv3'
#
# [*amqp_durable_queues*]
#   (Optional) Use durable queues in amqp.
#   Defaults to false
#
# == keystone authentication options
#
# [*auth_uri*]
#   (Optional) Specifies the Authentication URI for Heat to use.
#   Located in heat.conf.
#   Defaults to false,
#   which uses: "${keystone_protocol}://${keystone_host}:5000/v2.0"

# [*keystone_host*]
#
# [*keystone_port*]
#
# [*keystone_protocol*]
#
# [*keystone_user*]
#
# [*keystone_tenant*]
#
# [*keystone_password*]
#
# [*keystone_ec2_uri*]
#
# ==== Various QPID options (Optional)
#
# [*qpid_hostname*]
#
# [*qpid_port*]
#
# [*qpid_username*]
#
# [*qpid_password*]
#
# [*qpid_heartbeat*]
#
# [*qpid_protocol*]
#
# [*qpid_tcp_nodelay*]
#
# [*qpid_reconnect*]
#
# [*qpid_reconnect_timeout*]
#
# [*qpid_reconnect_limit*]
#
# [*qpid_reconnect_interval*]
#
# [*qpid_reconnect_interval_min*]
#
# [*qpid_reconnect_interval_max*]
#
# [*database_connection*]
#   (Optional) Url used to connect to database.
#   Defaults to 'sqlite:////var/lib/heat/heat.sqlite'.
#
# [*database_idle_timeout*]
#   (Optional) Timeout before idle db connections are reaped.
#   Defaults to 3600.
#
# [*use_syslog*]
#   (Optional) Use syslog for logging.
#   Defaults to false.
#
# [*log_facility*]
#   (Optional) Syslog facility to receive log lines.
#   Defaults to LOG_USER.
#
# === Deprecated ParameterS
#
# [*mysql_module*]
#   Deprecated. Does nothing.
#
# [*sql_connection*]
#   Deprecated. Use database_connection instead.
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
  $database_connection         = 'sqlite:////var/lib/heat/heat.sqlite',
  $database_idle_timeout       = 3600,
  $use_syslog                  = false,
  $log_facility                = 'LOG_USER',
  #Deprecated parameters
  $mysql_module                = undef,
  $sql_connection              = undef,
) {

  include heat::params

  if $kombu_ssl_ca_certs and !$rabbit_use_ssl {
    fail('The kombu_ssl_ca_certs parameter requires rabbit_use_ssl to be set to true')
  }
  if $kombu_ssl_certfile and !$rabbit_use_ssl {
    fail('The kombu_ssl_certfile parameter requires rabbit_use_ssl to be set to true')
  }
  if $kombu_ssl_keyfile and !$rabbit_use_ssl {
    fail('The kombu_ssl_keyfile parameter requires rabbit_use_ssl to be set to true')
  }
  if ($kombu_ssl_certfile and !$kombu_ssl_keyfile) or ($kombu_ssl_keyfile and !$kombu_ssl_certfile) {
    fail('The kombu_ssl_certfile and kombu_ssl_keyfile parameters must be used together')
  }
  if $mysql_module {
    warning('The mysql_module parameter is deprecated. The latest 2.x mysql module will be used.')
  }

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
    ensure => directory,
    owner  => 'heat',
    group  => 'heat',
    mode   => '0750',
  }

  file { '/etc/heat/heat.conf':
    owner => 'heat',
    group => 'heat',
    mode  => '0640',
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
      'DEFAULT/rabbit_password'        : value => $rabbit_password, secret => true;
      'DEFAULT/rabbit_virtual_host'    : value => $rabbit_virtual_host;
      'DEFAULT/rabbit_use_ssl'         : value => $rabbit_use_ssl;
      'DEFAULT/amqp_durable_queues'    : value => $amqp_durable_queues;
    }

    if $rabbit_use_ssl {

      if $kombu_ssl_ca_certs {
        heat_config { 'DEFAULT/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs; }
      } else {
        heat_config { 'DEFAULT/kombu_ssl_ca_certs': ensure => absent; }
      }

      if $kombu_ssl_certfile or $kombu_ssl_keyfile {
        heat_config {
          'DEFAULT/kombu_ssl_certfile': value => $kombu_ssl_certfile;
          'DEFAULT/kombu_ssl_keyfile':  value => $kombu_ssl_keyfile;
        }
      } else {
        heat_config {
          'DEFAULT/kombu_ssl_certfile': ensure => absent;
          'DEFAULT/kombu_ssl_keyfile':  ensure => absent;
        }
      }

      if $kombu_ssl_version {
        heat_config { 'DEFAULT/kombu_ssl_version':  value => $kombu_ssl_version; }
      } else {
        heat_config { 'DEFAULT/kombu_ssl_version':  ensure => absent; }
      }

    } else {
      heat_config {
        'DEFAULT/kombu_ssl_version':  ensure => absent;
        'DEFAULT/kombu_ssl_ca_certs': ensure => absent;
        'DEFAULT/kombu_ssl_certfile': ensure => absent;
        'DEFAULT/kombu_ssl_keyfile':  ensure => absent;
      }
    }

  }

  if $rpc_backend == 'heat.openstack.common.rpc.impl_qpid' {

    heat_config {
      'DEFAULT/qpid_hostname'               : value => $qpid_hostname;
      'DEFAULT/qpid_port'                   : value => $qpid_port;
      'DEFAULT/qpid_username'               : value => $qpid_username;
      'DEFAULT/qpid_password'               : value => $qpid_password, secret => true;
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
    warning('The sql_connection parameter is deprecated, use database_connection instead.')
    $database_connection_real = $sql_connection
  } else {
    $database_connection_real = $database_connection
  }

  if $database_connection_real {
    validate_re($database_connection_real,
      '(sqlite|mysql|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')

    case $database_connection_real {
      /^mysql:\/\//: {
        $backend_package = false
        require mysql::bindings
        require mysql::bindings::python
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
      'database/connection':
        value  => $database_connection_real,
        secret => true;
      'database/idle_timeout':
        value => $database_idle_timeout;
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
