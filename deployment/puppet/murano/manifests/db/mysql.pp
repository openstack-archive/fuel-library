class murano::db::mysql(
  $murano_db_password = 'murano',
  $murano_db_name     = 'murano',
  $murano_db_user     = 'murano',
  $murano_db_host     = 'localhost',
  $allowed_hosts      = undef,
  $charset            = 'utf8',
) {

  include 'murano::params'

  mysql::db { $murano_db_name :
    user         => $murano_db_user,
    password     => $murano_db_password,
    host         => $murano_db_host,
    charset      => $charset,
    grant        => ['all'],
  }

}
