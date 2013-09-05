class savanna::db::mysql(
  $password      = false,
  $dbname        = 'savanna',
  $user          = 'savanna',
  $dbhost        = 'localhost',
  $allowed_hosts = undef,
  $charset       = 'latin1',
) {

  include 'savanna::params'


  mysql::db {
    $dbname:
    user         => $user,
    password     => $password,
    host         => $::savanna::db::mysql::dbhost,
    charset      => $savanna::params::savanna_db_charset,
    # I may want to inject some sql
    #require      => Class['mysql::server'],
    grant         => ['all'],
  }
}
