class heat::db::mysql(
  $password      = 'heat',
  $dbname        = 'heat',
  $user          = 'heat',
  $dbhost        = 'localhost',
  $charset       = 'utf8',
) {

  include 'heat::params'

  mysql::db { $dbname :
    user         => $user,
    password     => $password,
    host         => $dbhost,
    charset      => $charset,
    grant        => ['all'],
  }

  Database[$dbname] ~> Exec['heat_db_sync']
  Database_user["${user}@${dbhost}"] ~> Exec['heat_db_sync']
  Database_grant["${user}@${dbhost}/${dbname}"] ~> Exec['heat_db_sync']

}
