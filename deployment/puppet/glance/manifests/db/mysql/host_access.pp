#
# Used to grant access to the glance mysql DB
#
define glance::db::mysql::host_access ($user, $password, $database)  {
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
