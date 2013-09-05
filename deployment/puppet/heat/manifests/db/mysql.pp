class heat::db::mysql(
  $password      = false,
  $dbname        = 'heat',
  $user          = 'heat',
  $dbhost        = 'localhost',
  $allowed_hosts = undef,
  $charset       = 'latin1',
) {

  include 'heat::params'

#  require 'mysql::python'
  # Create the db instance before openstack-heat if its installed
  Mysql::Db[$dbname] -> Anchor<| title == "heat-start" |>
  Mysql::Db[$dbname] ~> Exec<| title == 'heat-db-sync' |>

  mysql::db {
    $dbname:
    user         => $user,
    password     => $password,
    host         => $::heat::db::mysql::dbhost,
    charset      => $heat::params::heat_db_charset,
    require      => Class['mysql::server'],
    grant        => ['all'],
    notify       => Exec['heat-manage db_sync']
  }
}
