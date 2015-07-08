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
# [*service_name*]
#   (optional) The name of the neutron-server service
#   Defaults to 'neutron-server'
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
#   (optional) DEPRECATED. The keystone host
#   Defaults to localhost.
#
# [*auth_protocol*]
#   (optional) DEPRECATED. The protocol used to access the auth host
#   Defaults to http.
#
# [*auth_port*]
#   (optional) DEPRECATED. The keystone auth port
#   Defaults to 35357.
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
# [*auth_uri*]
#   (optional) Complete public Identity API endpoint.
#   Defaults to: false
#
# [*identity_uri*]
#   (optional) Complete admin Identity API endpoint.
#   Defaults to: false
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
# [*database_min_pool_size*]
#   (optional) Minimum number of SQL connections to keep open in a pool.
#   Defaults to: 1
#
# [*database_max_pool_size*]
#   (optional) Maximum number of SQL connections to keep open in a pool.
#   Defaults to: 10
#
# [*database_max_overflow*]
#   (optional) If set, use this value for max_overflow with sqlalchemy.
#   Defaults to: 20
#
# [*sync_db*]
#   (optional) Run neutron-db-manage on api nodes after installing the package.
#   Defaults to false
#
# [*api_workers*]
#   (optional) Number of separate worker processes to spawn.
#   The default, count of machine's processors, runs the worker thread in the
#   current process.
#   Greater than 0 launches that number of child processes as workers.
#   The parent process manages them.
#   Defaults to: $::processorcount
#
# [*rpc_workers*]
#   (optional) Number of separate RPC worker processes to spawn.
#   The default, count of machine's processors, runs the worker thread in the
#   current process.
#   Greater than 0 launches that number of child processes as workers.
#   The parent process manages them.
#   Defaults to: $::processorcount
#
# [*agent_down_time*]
#   (optional) Seconds to regard the agent as down; should be at least twice
#   report_interval, to be sure the agent is down for good.
#   agent_down_time is a config for neutron-server, set by class neutron::server
#   report_interval is a config for neutron agents, set by class neutron
#   Defaults to: 75
#
# [*state_path*]
#   (optional) Deprecated.  Use state_path parameter on base neutron class instead.
#
# [*lock_path*]
#   (optional) Deprecated.  Use lock_path parameter on base neutron class instead.
#
# [*router_scheduler_driver*]
#   (optional) Driver to use for scheduling router to a default L3 agent. Could be:
#   neutron.scheduler.l3_agent_scheduler.ChanceScheduler to schedule a router in a random way
#   neutron.scheduler.l3_agent_scheduler.LeastRoutersScheduler to allocate on an L3 agent with the least number of routers bound.
#   Defaults to: neutron.scheduler.l3_agent_scheduler.ChanceScheduler
#
# [*mysql_module*]
#   (optional) Deprecated. Does nothing.
#
# [*router_distributed*]
#   (optional) Setting the "router_distributed" flag to "True" will default to the creation
#   of distributed tenant routers.
#   Also can be the type of the router on the create request (admin-only attribute).
#   Defaults to false
#
# [*allow_automatic_l3agent_failover*]
#   (optional) Allow automatic rescheduling of routers from dead L3 agents with
#   admin_state_up set to True to alive agents.
#   Defaults to false
#
# [*l3_ha*]
#   (optional) Enable high availability for virtual routers.
#   Defaults to false
#
# [*max_l3_agents_per_router*]
#   (optional) Maximum number of l3 agents which a HA router will be scheduled on. If set to '0', a router will be scheduled on every agent.
#   Defaults to '3'
#
# [*min_l3_agents_per_router*]
#   (optional) Minimum number of l3 agents which a HA router will be scheduled on.
#   Defaults to '2'
#
# [*l3_ha_net_cidr*]
#   (optional) CIDR of the administrative network if HA mode is enabled.
#   Defaults to '169.254.192.0/18'
#
class neutron::server (
  $package_ensure                   = 'present',
  $enabled                          = true,
  $manage_service                   = true,
  $service_name                     = $::neutron::params::server_service,
  $auth_password                    = false,
  $auth_type                        = 'keystone',
  $auth_tenant                      = 'services',
  $auth_user                        = 'neutron',
  $auth_uri                         = false,
  $identity_uri                     = false,
  $database_connection              = 'sqlite:////var/lib/neutron/ovs.sqlite',
  $database_max_retries             = 10,
  $database_idle_timeout            = 3600,
  $database_retry_interval          = 10,
  $database_min_pool_size           = 1,
  $database_max_pool_size           = 10,
  $database_max_overflow            = 20,
  $sync_db                          = false,
  $api_workers                      = $::processorcount,
  $rpc_workers                      = $::processorcount,
  $agent_down_time                  = '75',
  $router_scheduler_driver          = 'neutron.scheduler.l3_agent_scheduler.ChanceScheduler',
  $router_distributed               = false,
  $allow_automatic_l3agent_failover = false,
  $l3_ha                            = false,
  $max_l3_agents_per_router         = 3,
  $min_l3_agents_per_router         = 2,
  $l3_ha_net_cidr                   = '169.254.192.0/18',
  # DEPRECATED PARAMETERS
  $auth_host                        = 'localhost',
  $auth_port                        = '35357',
  $auth_protocol                    = 'http',
  $auth_admin_prefix                = false,
  $mysql_module                     = undef,
  $log_dir                          = undef,
  $log_file                         = undef,
  $report_interval                  = undef,
  $state_path                       = undef,
  $lock_path                        = undef,
) {

  include ::neutron::params
  include ::neutron::policy
  require keystone::python

  Nova_admin_tenant_id_setter<||> ~> Service['neutron-server']
  Neutron_config<||>     ~> Service['neutron-server']
  Neutron_api_config<||> ~> Service['neutron-server']
  Class['neutron::policy'] ~> Service['neutron-server']

  if $l3_ha {
    if $min_l3_agents_per_router <= $max_l3_agents_per_router or $max_l3_agents_per_router == 0 {
      neutron_config {
        'DEFAULT/l3_ha':                    value => true;
        'DEFAULT/max_l3_agents_per_router': value => $max_l3_agents_per_router;
        'DEFAULT/min_l3_agents_per_router': value => $min_l3_agents_per_router;
        'DEFAULT/l3_ha_net_cidr':           value => $l3_ha_net_cidr;
      }
    } else {
      fail('min_l3_agents_per_router should be less than or equal to max_l3_agents_per_router.')
    }
  } else {
      neutron_config {
        'DEFAULT/l3_ha':                    value => false;
      }
  }

  if $mysql_module {
    warning('The mysql_module parameter is deprecated. The latest 2.x mysql module will be used.')
  }

  validate_re($database_connection, '(sqlite|mysql|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')

  case $database_connection {
    /mysql:\/\/\S+:\S+@\S+\/\S+/: {
      require 'mysql::bindings'
      require 'mysql::bindings::python'
    }
    /postgresql:\/\/\S+:\S+@\S+\/\S+/: {
      $backend_package = 'python-psycopg2'
    }
    /sqlite:\/\//: {
      $backend_package = 'python-pysqlite2'
    }
    default: {
      fail("Invalid database_connection parameter: ${database_connection}")
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
      subscribe   => Neutron_config['database/connection'],
      refreshonly => true
    }
    Neutron_config<||> ~> Exec['neutron-db-sync']
  }

  neutron_config {
    'DEFAULT/api_workers':                      value => $api_workers;
    'DEFAULT/rpc_workers':                      value => $rpc_workers;
    'DEFAULT/agent_down_time':                  value => $agent_down_time;
    'DEFAULT/router_scheduler_driver':          value => $router_scheduler_driver;
    'DEFAULT/router_distributed':               value => $router_distributed;
    'DEFAULT/allow_automatic_l3agent_failover': value => $allow_automatic_l3agent_failover;
    'database/connection':                      value => $database_connection, secret => true;
    'database/idle_timeout':                    value => $database_idle_timeout;
    'database/retry_interval':                  value => $database_retry_interval;
    'database/max_retries':                     value => $database_max_retries;
    'database/min_pool_size':                   value => $database_min_pool_size;
    'database/max_pool_size':                   value => $database_max_pool_size;
    'database/max_overflow':                    value => $database_max_overflow;
  }

  if $state_path {
    # If we got state_path here, display deprecation warning and override the value from
    # the base class.  This preserves the behavior of before state_path was deprecated.

    warning('The state_path parameter is deprecated.  Use the state_path parameter on the base neutron class instead.')

    Neutron_config <| title == 'DEFAULT/state_path' |> {
      value => $state_path,
    }
  }

  if $lock_path {
    # If we got lock_path here, display deprecation warning and override the value from
    # the base class.  This preserves the behavior of before lock_path was deprecated.

    warning('The lock_path parameter is deprecated.  Use the lock_path parameter on the base neutron class instead.')

    Neutron_config <| title == 'DEFAULT/lock_path' |> {
      value  => $lock_path,
    }
  }

  if ($::neutron::params::server_package) {
    Package['neutron-server'] -> Neutron_api_config<||>
    Package['neutron-server'] -> Neutron_config<||>
    Package['neutron-server'] -> Service['neutron-server']
    Package['neutron-server'] -> Class['neutron::policy']
    package { 'neutron-server':
      ensure => $package_ensure,
      name   => $::neutron::params::server_package,
      tag    => 'openstack',
    }
  } else {
    # Some platforms (RedHat) does not provide a neutron-server package.
    # The neutron api config file is provided by the neutron package.
    Package['neutron'] -> Class['neutron::policy']
    Package['neutron'] -> Neutron_api_config<||>
  }

  if ($auth_type == 'keystone') {

    if ($auth_password == false) {
      fail('$auth_password must be set when using keystone authentication.')
    } else {

      neutron_config {
        'keystone_authtoken/admin_tenant_name': value => $auth_tenant;
        'keystone_authtoken/admin_user':        value => $auth_user;
        'keystone_authtoken/admin_password':    value => $auth_password, secret => true;
      }

      neutron_api_config {
        'filter:authtoken/admin_tenant_name': value => $auth_tenant;
        'filter:authtoken/admin_user':        value => $auth_user;
        'filter:authtoken/admin_password':    value => $auth_password, secret => true;
      }

      # if both auth_uri and identity_uri are set we skip these deprecated settings entirely
      if !$auth_uri or !$identity_uri {

        if $auth_admin_prefix {
          warning('The auth_admin_prefix parameter is deprecated. Please use auth_uri and identity_uri instead.')
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

        if $auth_host {
          warning('The auth_host parameter is deprecated. Please use auth_uri and identity_uri instead.')
          neutron_config {
            'keystone_authtoken/auth_host': value => $auth_host;
          }
          neutron_api_config {
            'filter:authtoken/auth_host': value => $auth_host;
          }
        } else{
          neutron_config {
            'keystone_authtoken/auth_host': ensure => absent;
          }
          neutron_api_config {
            'filter:authtoken/auth_host': ensure => absent;
          }
        }

        if $auth_port {
          warning('The auth_port parameter is deprecated. Please use auth_uri and identity_uri instead.')
          neutron_config {
            'keystone_authtoken/auth_port': value => $auth_port;
          }
          neutron_api_config {
            'filter:authtoken/auth_port': value => $auth_port;
          }
        } else{
          neutron_config {
            'keystone_authtoken/auth_port': ensure => absent;
          }
          neutron_api_config {
            'filter:authtoken/auth_port': ensure => absent;
          }
        }

        if $auth_protocol {
          warning('The auth_protocol parameter is deprecated. Please use auth_uri and identity_uri instead.')
          neutron_config {
            'keystone_authtoken/auth_protocol': value => $auth_protocol;
          }
          neutron_api_config {
            'filter:authtoken/auth_protocol': value => $auth_protocol;
          }
        } else{
          neutron_config {
            'keystone_authtoken/auth_protocol': ensure => absent;
          }
          neutron_api_config {
            'filter:authtoken/auth_protocol': ensure => absent;
          }
        }
      } else {
        neutron_config {
          'keystone_authtoken/auth_admin_prefix': ensure => absent;
          'keystone_authtoken/auth_host': ensure => absent;
          'keystone_authtoken/auth_port': ensure => absent;
          'keystone_authtoken/auth_protocol': ensure => absent;
        }
        neutron_api_config {
          'filter:authtoken/auth_admin_prefix': ensure => absent;
          'filter:authtoken/auth_host': ensure => absent;
          'filter:authtoken/auth_port': ensure => absent;
          'filter:authtoken/auth_protocol': ensure => absent;
        }
      }

      if $auth_uri {
        $auth_uri_real = $auth_uri
      } elsif $auth_host and $auth_protocol and $auth_port {
        $auth_uri_real = "${auth_protocol}://${auth_host}:5000/"
      }

      neutron_config {
        'keystone_authtoken/auth_uri': value => $auth_uri_real;
      }
      neutron_api_config {
        'filter:authtoken/auth_uri': value => $auth_uri_real;
      }

      if $identity_uri {
        neutron_config {
          'keystone_authtoken/identity_uri': value => $identity_uri;
        }
        neutron_api_config {
          'filter:authtoken/identity_uri': value => $identity_uri;
        }
      } else {
        neutron_config {
          'keystone_authtoken/identity_uri': ensure => absent;
        }
        neutron_api_config {
          'filter:authtoken/identity_uri': ensure => absent;
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
    name       => $service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Class['neutron'],
  }
}
