# Allow a user to access the database for the service
#
# == Namevar
#  String with the form dbname_host. The host part of the string is the host
#  to allow
#
# == Parameters
#  [*user*]
#    username to allow
#
#  [*password_hash*]
#    user password hash
#
#  [*database*]
#    the database name
#
#  [*privileges*]
#    the privileges to grant to this user
#
define openstacklib::db::mysql::host_access (
# Temp mysql_module variable untill mysql is up to date
  $mysql_module,
  $user,
  $password_hash,
  $database,
  $privileges,
) {
  validate_re($title, '_', 'Title must be $dbname_$host')

  $host = inline_template('<%= @title.split("_").last %>')

  if ($mysql_module >= 2.2) {
  mysql_user { "${user}@${host}":
    password_hash => $password_hash,
    require       => Mysql_database[$database],
  }

  mysql_grant { "${user}@${host}/${database}.*":
    privileges => $privileges,
    table      => "${database}.*",
    require    => Mysql_user["${user}@${host}"],
    user       => "${user}@${host}",
  }
  }
else {
    database_user { "${user}@${host}":
      password_hash => $password_hash,
      provider      => 'mysql',
      require       => Database[$database],
    }
    database_grant { "${user}@${host}/${database}":
      # TODO figure out which privileges to grant.
      privileges => 'all',
      provider   => 'mysql',
      require    => Database_user["${user}@${host}"]
    }
  }
}
