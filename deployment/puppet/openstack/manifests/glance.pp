#
# == Class: openstack::glance
#
# Installs and configures Glance
# Assumes the following:
#   - Keystone for authentication
#   - keystone tenant: services
#   - keystone username: glance
#   - storage backend: file
#
# === Parameters
#
# [db_host] Host where DB resides. Required.
# [glance_user_password] Password for glance auth user. Required.
# [glance_db_password] Password for glance DB. Required.
# [keystone_host] Host whre keystone is running. Optional. Defaults to '127.0.0.1'
# [auth_uri] URI used for auth. Optional. Defaults to "http://${keystone_host}:5000/"
# [db_type] Type of sql databse to use. Optional. Defaults to 'mysql'
# [glance_db_user] Name of glance DB user. Optional. Defaults to 'glance'
# [glance_db_dbname] Name of glance DB. Optional. Defaults to 'glance'
# [verbose] Log verbosely. Optional. Defaults to 'False'
# [enabled] Used to indicate if the service should be active (true) or passive (false).
#   Optional. Defaults to true
# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option 
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
#
# === Example
#
# class { 'openstack::glance':
#   glance_user_password => 'changeme',
#   db_password          => 'changeme',
#   db_host              => '127.0.0.1',
# }

class openstack::glance (
  $db_host,
  $glance_user_password,
  $glance_db_password,
  $bind_host            = '127.0.0.1',
  $keystone_host        = '127.0.0.1',
  $registry_host        = '127.0.0.1',
  $auth_uri             = "http://127.0.0.1:5000/",
  $db_type              = 'mysql',
  $glance_db_user       = 'glance',
  $glance_db_dbname     = 'glance',
  $glance_backend       = 'file',
  $verbose              = 'False',
  $enabled              = true,
  $use_syslog           = false,
  # Facility is common for all glance services
  $syslog_log_facility  = 'LOCAL2',
) {

  # Configure the db string
  case $db_type {
    'mysql': {
      $sql_connection = "mysql://${glance_db_user}:${glance_db_password}@${db_host}/${glance_db_dbname}"
    }
  }

  # Install and configure glance-api
  class { 'glance::api':
    verbose           => $verbose,
    debug             => $verbose,
    bind_host         => $bind_host,
    auth_type         => 'keystone',
    auth_port         => '35357',
    auth_host         => $keystone_host,
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    sql_connection    => $sql_connection,
    enabled           => $enabled,
    registry_host     => $registry_host,
    use_syslog        => $use_syslog,
  }

  # Install and configure glance-registry
  class { 'glance::registry':
    verbose           => $verbose,
    debug             => $verbose,
    bind_host         => $bind_host,
    auth_host         => $keystone_host,
    auth_port         => '35357',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    sql_connection    => $sql_connection,
    enabled           => $enabled,
    use_syslog        => $use_syslog,
  }

  # Configure file storage backend


 if $glance_backend == "swift" {
    if !defined(Package['swift']) {
      include ::swift::params
      package { "swift":
        name   => $::swift::params::package_name,
        ensure =>present
      }
    }
    Package["swift"] ~> Service['glance-api']

    class { "glance::backend::$glance_backend":
      swift_store_user => "services:glance",
      swift_store_key=> $glance_user_password,
      swift_store_create_container_on_put => "True",
      swift_store_auth_address => "http://${keystone_host}:5000/v2.0/"
    }
  } else {
    class { "glance::backend::$glance_backend": }
  }
}
