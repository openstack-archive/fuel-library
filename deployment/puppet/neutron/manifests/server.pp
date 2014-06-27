# == Class: neutron::server
#
# Setup and configure the neutron API endpoint
#
# === Parameters
#
# [*package_ensure*]
#   (optional) The state of the package
#   Defaults to present
#
# [*enabled*]
#   (optional) The state of the service
#   Defaults to true
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*log_file*]
#   REMOVED: Use log_file of neutron class instead.
#
# [*log_dir*]
#   REMOVED: Use log_dir of neutron class instead.
#
# [*auth_password*]
#   (optional) The password to use for authentication (keystone)
#   Defaults to false. Set a value unless you are using noauth
#
# [*auth_type*]
#   (optional) What auth system to use
#   Defaults to 'keystone'. Can other be 'noauth'
#
# [*auth_host*]
#   (optional) The keystone host
#   Defaults to localhost
#
# [*auth_protocol*]
#   (optional) The protocol used to access the auth host
#   Defaults to http.
#
# [*auth_port*]
#   (optional) The keystone auth port
#   Defaults to 35357
#
# [*auth_admin_prefix*]
#   (optional) The admin_prefix used to admin endpoint of the auth host
#   This allow admin auth URIs like http://auth_host:35357/keystone.
#   (where '/keystone' is the admin prefix)
#   Defaults to false for empty. If defined, should be a string with a leading '/' and no trailing '/'.
#
# [*auth_tenant*]
#   (optional) The tenant of the auth user
#   Defaults to services
#
# [*auth_user*]
#   (optional) The name of the auth user
#   Defaults to neutron
#
# [*auth_protocol*]
#   (optional) The protocol to connect to keystone
#   Defaults to http
#
# [*auth_uri*]
#   (optional) Complete public Identity API endpoint.
#   Defaults to: $auth_protocol://$auth_host:5000/
#
# [*database_connection*]
#   (optional) Connection url for the neutron database.
#   (Defaults to 'sqlite:////var/lib/neutron/ovs.sqlite')
#
# [*sql_connection*]
#   DEPRECATED: Use database_connection instead.
#
# [*connection*]
#   DEPRECATED: Use database_connection instead.
#
# [*database_max_retries*]
#   (optional) Maximum database connection retries during startup.
#   (Defaults to 10)
#
# [*sql_max_retries*]
#   DEPRECATED: Use database_max_retries instead.
#
# [*max_retries*]
#   DEPRECATED: Use database_max_retries instead.
#
# [*database_idle_timeout*]
#   (optional) Timeout before idle database connections are reaped.
#   Deprecates sql_idle_timeout
#   (Defaults to 3600)
#
# [*sql_idle_timeout*]
#   DEPRECATED: Use database_idle_timeout instead.
#
# [*idle_timeout*]
#   DEPRECATED: Use database_idle_timeout instead.
#
# [*database_retry_interval*]
#   (optional) Interval between retries of opening a database connection.
#   (Defaults to 10)
#
# [*sql_reconnect_interval*]
#   DEPRECATED: Use database_retry_interval instead.
#
# [*retry_interval*]
#   DEPRECATED: Use database_retry_interval instead.
#
# [*sync_db*]
#   (optional) Run neutron-db-manage on api nodes after installing the package.
#   Defaults to false
#
# [*api_workers*]
#   (optional) Number of separate worker processes to spawn.
#   The default, 0, runs the worker thread in the current process.
#   Greater than 0 launches that number of child processes as workers.
#   The parent process manages them.
#   Defaults to: 0
#
# [*agent_down_time*]
#   (optional) Seconds to regard the agent as down; should be at least twice
#   report_interval, to be sure the agent is down for good.
#   agent_down_time is a config for neutron-server, set by class neutron::server
#   report_interval is a config for neutron agents, set by class neutron
#   Defaults to: 75
#
# [*router_scheduler_driver*]
#   (optional) Driver to use for scheduling router to a default L3 agent. Could be:
#   neutron.scheduler.l3_agent_scheduler.ChanceScheduler to schedule a router in a random way
#   neutron.scheduler.l3_agent_scheduler.LeastRoutersScheduler to allocate on an L3 agent with the least number of routers bound.
#   Defaults to: neutron.scheduler.l3_agent_scheduler.ChanceScheduler
#
# [*mysql_module*]
#   (optional) Mysql puppet module version to use. Tested versions
#   include 0.9 and 2.2
#   Defaults to: '0.9'
#
class neutron::server (
  $package_ensure          = 'present',
  $enabled                 = true,
  $manage_service          = true,
  $auth_password           = false,
  $auth_type               = 'keystone',
  $auth_host               = 'localhost',
  $auth_port               = '35357',
  $auth_admin_prefix       = false,
  $auth_tenant             = 'services',
  $auth_user               = 'neutron',
  $auth_protocol           = 'http',
  $auth_uri                = false,
  $database_connection     = 'sqlite:////var/lib/neutron/ovs.sqlite',
  $database_max_retries    = 10,
  $database_idle_timeout   = 3600,
  $database_retry_interval = 10,
  $sync_db                 = false,
  $api_workers             = '0',
  $agent_down_time         = '75',
  $router_scheduler_driver = 'neutron.scheduler.l3_agent_scheduler.ChanceScheduler',
  $mysql_module            = '0.9',
  # DEPRECATED PARAMETERS
  $sql_connection          = undef,
  $connection              = undef,
  $sql_max_retries         = undef,
  $max_retries             = undef,
  $sql_idle_timeout        = undef,
  $idle_timeout            = undef,
  $sql_reconnect_interval  = undef,
  $retry_interval          = undef,
  $log_dir                 = undef,
  $log_file                = undef,
  $report_interval         = undef,
) {

  include neutron::params
  require keystone::python

  Neutron_config<||>     ~> Service['neutron-server']
  Neutron_api_config<||> ~> Service['neutron-server']

  if $sql_connection {
    warning('The sql_connection parameter is deprecated, use database_connection instead.')
    $database_connection_real = $sql_connection
  } elsif $connection {
    warning('The connection parameter is deprecated, use database_connection instead.')
    $database_connection_real = $connection
  } else {
    $database_connection_real = $database_connection
  }

  if $sql_max_retries {
    warning('The sql_max_retries parameter is deprecated, use database_max_retries instead.')
    $database_max_retries_real = $sql_max_retries
  } elsif $max_retries {
    warning('The max_retries parameter is deprecated, use database_max_retries instead.')
    $database_max_retries_real = $max_retries
  } else {
    $database_max_retries_real = $database_max_retries
  }

  if $sql_idle_timeout {
    warning('The sql_idle_timeout parameter is deprecated, use database_idle_timeout instead.')
    $database_idle_timeout_real = $sql_idle_timeout
  } elsif $idle_timeout {
    warning('The dle_timeout parameter is deprecated, use database_idle_timeout instead.')
    $database_idle_timeout_real = $idle_timeout
  } else {
    $database_idle_timeout_real = $database_idle_timeout
  }

  if $sql_reconnect_interval {
    warning('The sql_reconnect_interval parameter is deprecated, use database_retry_interval instead.')
    $database_retry_interval_real = $sql_reconnect_interval
  } elsif $retry_interval {
    warning('The retry_interval parameter is deprecated, use database_retry_interval instead.')
    $database_retry_interval_real = $retry_interval
  } else {
    $database_retry_interval_real = $database_retry_interval
  }

  if $log_dir {
    fail('The log_dir parameter is removed, use log_dir of neutron class instead.')
  }

  if $log_file {
    fail('The log_file parameter is removed, use log_file of neutron class instead.')
  }

  if $report_interval {
    fail('The report_interval is removed, use report_interval of neutron class instead.')
  }

  validate_re($database_connection_real, '(sqlite|mysql|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')

  case $database_connection_real {
    /mysql:\/\/\S+:\S+@\S+\/\S+/: {
      if ($mysql_module >= 2.2) {
        require 'mysql::bindings'
        require 'mysql::bindings::python'
      } else {
        require 'mysql::python'
      }
    }
    /postgresql:\/\/\S+:\S+@\S+\/\S+/: {
      $backend_package = 'python-psycopg2'
    }
    /sqlite:\/\//: {
      $backend_package = 'python-pysqlite2'
    }
    default: {
      fail("Invalid database_connection parameter: ${database_connection_real}")
    }
  }

  if $sync_db {
    if ($::neutron::params::server_package) {
      # Debian platforms
      Package<| title == 'neutron-server' |> ~> Exec['neutron-db-sync']
    } else {
      # RH platforms
      Package<| title == 'neutron' |> ~> Exec['neutron-db-sync']
    }
    exec { 'neutron-db-sync':
      command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
      path        => '/usr/bin',
      before      => Service['neutron-server'],
      require     => Neutron_config['database/connection'],
      refreshonly => true
    }
  }

  neutron_config {
    'DEFAULT/api_workers':             value => $api_workers;
    'DEFAULT/agent_down_time':         value => $agent_down_time;
    'DEFAULT/router_scheduler_driver': value => $router_scheduler_driver;
    'database/connection':             value => $database_connection_real;
    'database/idle_timeout':           value => $database_idle_timeout_real;
    'database/retry_interval':         value => $database_retry_interval_real;
    'database/max_retries':            value => $database_max_retries_real;
  }

  if ($::neutron::params::server_package) {
    Package['neutron-server'] -> Neutron_api_config<||>
    Package['neutron-server'] -> Neutron_config<||>
    Package['neutron-server'] -> Service['neutron-server']
    package { 'neutron-server':
      ensure => $package_ensure,
      name   => $::neutron::params::server_package,
    }
  } else {
    # Some platforms (RedHat) does not provide a neutron-server package.
    # The neutron api config file is provided by the neutron package.
    Package['neutron'] -> Neutron_api_config<||>
  }

  if ($auth_type == 'keystone') {

    if ($auth_password == false) {
      fail('$auth_password must be set when using keystone authentication.')
    } else {
      neutron_config {
        'keystone_authtoken/auth_host':         value => $auth_host;
        'keystone_authtoken/auth_port':         value => $auth_port;
        'keystone_authtoken/auth_protocol':     value => $auth_protocol;
        'keystone_authtoken/admin_tenant_name': value => $auth_tenant;
        'keystone_authtoken/admin_user':        value => $auth_user;
        'keystone_authtoken/admin_password':    value => $auth_password;
      }

      neutron_api_config {
        'filter:authtoken/auth_host':         value => $auth_host;
        'filter:authtoken/auth_port':         value => $auth_port;
        'filter:authtoken/auth_protocol':     value => $auth_protocol;
        'filter:authtoken/admin_tenant_name': value => $auth_tenant;
        'filter:authtoken/admin_user':        value => $auth_user;
        'filter:authtoken/admin_password':    value => $auth_password;
      }

      if $auth_admin_prefix {
        validate_re($auth_admin_prefix, '^(/.+[^/])?$')
        neutron_config {
          'keystone_authtoken/auth_admin_prefix': value => $auth_admin_prefix;
        }
        neutron_api_config {
          'filter:authtoken/auth_admin_prefix': value => $auth_admin_prefix;
        }
      } else {
        neutron_config {
          'keystone_authtoken/auth_admin_prefix': ensure => absent;
        }
        neutron_api_config {
          'filter:authtoken/auth_admin_prefix': ensure => absent;
        }
      }

      if $auth_uri {
        neutron_config {
          'keystone_authtoken/auth_uri': value => $auth_uri;
        }
        neutron_api_config {
          'filter:authtoken/auth_uri': value => $auth_uri;
        }
      } else {
        neutron_config {
          'keystone_authtoken/auth_uri': value => "${auth_protocol}://${auth_host}:5000/";
        }
        neutron_api_config {
          'filter:authtoken/auth_uri': value => "${auth_protocol}://${auth_host}:5000/";
        }
      }

    }

  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'neutron-server':
    ensure     => $service_ensure,
    name       => $::neutron::params::server_service,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Class['neutron'],
  }
}
