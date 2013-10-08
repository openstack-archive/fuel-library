class savanna::db::mysql(
  $password = false,
  $dbname   = 'savanna',
  $user     = 'savanna',
  $dbhost   = 'localhost',
  $charset  = 'utf8',
) {

  include 'savanna::params'

  mysql::db { $dbname :
    user     => $user,
    password => $password,
    host     => $dbhost,
    charset  => $charset,
    grant    => ['all'],
  }

}
