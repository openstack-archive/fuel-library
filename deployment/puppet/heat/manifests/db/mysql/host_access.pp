# Allow a user to access the heat database
#
# == Namevar
#  The host to allow
#
# == Parameters
#  [*user*]
#    username to allow
#
#  [*password*]
#    user password
#
#  [*database*]
#    the database name
#
define heat::db::mysql::host_access ($user, $password, $database, $mysql_module)  {
  if ($mysql_module >= 2.2) {
    mysql_user { "${user}@${name}":
      password_hash => mysql_password($password),
      require       => Mysql_database[$database],
    }

    mysql_grant { "${user}@${name}/${database}.*":
      privileges => ['ALL'],
      options    => ['GRANT'],
      table      => "${database}.*",
      require    => Mysql_user["${user}@${name}"],
      user       => "${user}@${name}"
    }
  } else {
    database_user { "${user}@${name}":
      password_hash => mysql_password($password),
      provider      => 'mysql',
      require       => Database[$database],
    }
    database_grant { "${user}@${name}/${database}":
      # TODO figure out which privileges to grant.
      privileges => 'all',
      provider   => 'mysql',
      require    => Database_user["${user}@${name}"]
    }
  }
}
