class murano::db::mysql(
  $password      = false,
  $dbname        = 'murano',
  $user          = 'murano',
  $dbhost        = 'localhost',
  $allowed_hosts = undef,
  $charset       = 'latin1',
) {

  include 'murano::params'


  mysql::db {
    $dbname:
    user         => $user,
    password     => $password,
    host         => $::murano::db::mysql::dbhost,
    charset      => $murano::params::murano_db_charset,
    # I may want to inject some sql
    #require      => Class['mysql::server'],
    grant         => ['all'],
  }
}
