# == Definition: openstacklib::db::mysql
#
# This resource configures a mysql database for an OpenStack service
#
# == Parameters:
#
#  [*password_hash*]
#    Password hash to use for the database user for this service;
#    string; required
#
#  [*mysql_module*]
#    Temp mysql_module vars that needed until mysql module is synced
#    do hardcode mysql_module=3.4 to avoid adding it to all modules
#
#  [*dbname*]
#    The name of the database
#    string; optional; default to the $title of the resource, i.e. 'nova'
#
#  [*user*]
#    The database user to create;
#    string; optional; default to the $title of the resource, i.e. 'nova'
#
#  [*host*]
#    The IP address or hostname of the user in mysql_grant;
#    string; optional; default to '127.0.0.1'
#
#  [*charset*]
#    The charset to use for the database;
#    string; optional; default to 'utf8'
#
#  [*collate*]
#    The collate to use for the database;
#    string; optional; default to 'utf8_general_ci'
#
#  [*allowed_hosts*]
#    Additional hosts that are allowed to access this database;
#    array or string; optional; default to undef
#
#  [*privileges*]
#    Privileges given to the database user;
#    string or array of strings; optional; default to 'ALL'

define openstacklib::db::mysql (
  $password_hash,
  $mysql_module   = '0.3',
  $dbname         = $title,
  $user           = $title,
  $host           = '127.0.0.1',
  $charset        = 'utf8',
  $collate        = 'utf8_general_ci',
  $allowed_hosts  = [],
  $privileges     = 'ALL',
) {

  if ($mysql_module >= 2.2){
    include ::mysql::client

    mysql_database { $dbname:
      ensure  => present,
      charset => $charset,
      collate => $collate,
      require => [ Class['mysql::server'], Class['mysql::client'] ],
    }
  } else {

    require mysql::python
    mysql::db { $dbname:
      user     => $user,
      password => $password_hash,
      host     => $host,
      charset  => $charset,
      require  => Class['mysql::config'],
    }
  }

  $allowed_hosts_list = unique(concat(any2array($allowed_hosts), [$host]))
  $real_allowed_hosts = prefix($allowed_hosts_list, "${dbname}_")

  openstacklib::db::mysql::host_access { $real_allowed_hosts:
    mysql_module  => $mysql_module,
    user          => $user,
    password_hash => $password_hash,
    database      => $dbname,
    privileges    => $privileges,
  }
}
