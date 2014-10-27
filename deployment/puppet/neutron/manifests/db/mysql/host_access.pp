#
# Used to grant access to the neutron mysql DB
#
define neutron::db::mysql::host_access ($user, $password, $database, $mysql_module = '0.9')  {
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
