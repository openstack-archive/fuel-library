define mysql::replicator ($user, $password)  {
  database_user { "${user}@${name}":
    password_hash => mysql_password($password),
    provider => 'mysql',
  }
  database_grant { "${user}@${name}":
    privileges => ['Super_priv'],
    provider => 'mysql',
    require => Database_user["${user}@${name}"]
  }
}
