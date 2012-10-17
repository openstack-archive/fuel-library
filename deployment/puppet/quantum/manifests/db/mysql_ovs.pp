#
class quantum::db::mysql_ovs (
  $password,
  $dbname        = 'quantum',
  $user          = 'quantum',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'latin1',
  $cluster_id    = 'localzone'
) {

  Class['mysql::server'] -> Class['quantum::db::mysql_ovs']

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => $charset,
    require      => Class['mysql::config'],
  }

  if $allowed_hosts {
#    quantum::db::mysql::host_access { $allowed_hosts:
#     user      => $user,
#     password  => $password,
#     database  => $dbname,
#   }
    database_user { "${user}@${allowed_hosts}":
      password_hash => mysql_password($password),
      provider => 'mysql',
      require => Database[$dbname],
    }
    database_grant { "${user}@${allowed_hosts}/${dbname}":
      # TODO figure out which privileges to grant.
      privileges => "all",
      provider => 'mysql',
      require => Database_user["${user}@${allowed_hosts}"]
    }
  }

}
