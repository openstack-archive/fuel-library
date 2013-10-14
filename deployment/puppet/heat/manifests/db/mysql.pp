class heat::db::mysql(
  $password      = 'heat',
  $dbname        = 'heat',
  $user          = 'heat',
  $dbhost        = 'localhost',
  $charset       = 'utf8',
  $allowed_hosts = undef,
) {

  include 'heat::params'

  mysql::db { $dbname :
    user         => $user,
    password     => $password,
    host         => $dbhost,
    charset      => $charset,
    grant        => ['all'],
  }
  
  if $allowed_hosts {
    heat::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }

  Database[$dbname] ~> Exec['heat_db_sync']
  Database_user["${user}@${dbhost}"] ~> Exec['heat_db_sync']
  Database_grant["${user}@${dbhost}/${dbname}"] ~> Exec['heat_db_sync']

}
