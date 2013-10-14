class savanna::db::mysql(
  $password      = 'savanna',
  $dbname        = 'savanna',
  $user          = 'savanna',
  $dbhost        = 'localhost',
  $charset       = 'utf8',
  $allowed_hosts = undef,
) {

  include 'savanna::params'

  mysql::db { $dbname :
    user     => $user,
    password => $password,
    host     => $dbhost,
    charset  => $charset,
    grant    => ['all'],
  }

  if $allowed_hosts {
    savanna::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }
  
  Database[$dbname] -> Class['savanna::api']
  Database_user["${user}@${dbhost}"] -> Class['savanna::api']
  Database_grant["${user}@${dbhost}/${dbname}"] -> Class['savanna::api']

}
