# Configures the ceilometer database
# This class will install the required libraries depending on the driver
# specified in the connection_string parameter
#
# == Parameters
#  [*database_connection*]
#    the connection string. format: [driver]://[user]:[password]@[host]/[database]
#
#  [*sync_db*]
#    enable dbsync.
#
#  [*mysql_module*]
#    (optional) Deprecated. Does nothing.
#
class ceilometer::db (
  $database_connection = 'mysql://ceilometer:ceilometer@localhost/ceilometer',
  $sync_db             = true,
  $mysql_module        = undef,
) {

  include ::ceilometer::params

  if $mysql_module {
    warning('The mysql_module parameter is deprecated. The latest 2.x mysql module will be used.')
  }

  Package<| title == 'ceilometer-common' |> -> Class['ceilometer::db']

  validate_re($database_connection,
    '(sqlite|mysql|postgresql|mongodb):\/\/(\S+:\S+@\S+\/\S+)?')

  case $database_connection {
    /^mysql:\/\//: {
      $backend_package = false

      include ::mysql::bindings::python
      Package<| title == 'python-mysqldb' |> -> Class['ceilometer::db']
    }
    /^postgresql:\/\//: {
      $backend_package = $::ceilometer::params::psycopg_package_name
    }
    /^mongodb:\/\//: {
      $backend_package = $::ceilometer::params::pymongo_package_name
    }
    /^sqlite:\/\//: {
      $backend_package = $::ceilometer::params::sqlite_package_name
    }
    default: {
      fail('Unsupported backend configured')
    }
  }

  if $sync_db {
    $command = $::ceilometer::params::dbsync_command
  } else {
    $command = '/bin/true'
  }

  if $backend_package and !defined(Package[$backend_package]) {
    package {'ceilometer-backend-package':
      ensure => present,
      name   => $backend_package,
      tag    => 'openstack',
    }
  }

  ceilometer_config {
    'database/connection': value => $database_connection, secret => true;
  }

  Ceilometer_config['database/connection'] ~> Exec['ceilometer-dbsync']

  exec { 'ceilometer-dbsync':
    command     => $command,
    path        => '/usr/bin',
    user        => $::ceilometer::params::user,
    refreshonly => true,
    logoutput   => on_failure,
    subscribe   => Ceilometer_config['database/connection']
  }

}
