# db/allowed_hosts.pp
class nova::db::allowed_hosts ( $hosts, $user, $password, $database ) {
  define host_access ($user, $password, $database)  {
    database_user { "${user}@${name}":
      password_hash => mysql_password($password),
      provider => 'mysql',
      require => Database[$database],
    }
    database_grant { "${user}@${name}/${database}":
      # TODO figure out which privileges to grant.
      privileges => "all",
      provider => 'mysql',
      require => Database_user["${user}@${name}"]
    }
  }
  host_access { $hosts:
    user => $user,
    password => $password,
    database => $database,
  }
}
