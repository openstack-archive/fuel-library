class heat::db::mysql(
  $password      = false,
  $dbname        = 'heat',
  $user          = 'heat',
  $dbhost        = 'localhost',
  $charset       = 'latin1',
) {

  include 'heat::params'

  mysql::db { $dbname :
    user         => $user,
    password     => $password,
    host         => $dbhost,
    charset      => $charset,
    grant        => ['all'],
  }

  Class['mysql::server'] -> Mysql::Db[$dbname] ~> Exec['heat-manage db_sync']

}
