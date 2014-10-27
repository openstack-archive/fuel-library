# == Class: nova::db::postgresql
#
# Class that configures postgresql for nova
# Requires the Puppetlabs postgresql module.
#
# === Parameters:
#
# [*password*]
#   Password to use to connect to postgresql
#
# [*dbname*]
#   (optional) Name of the database to create for nova
#   Defaults to 'nova'
#
# [*user*]
#   (optional) Name of the user to connect to postgresql
#   Defaults to 'nova'
#
class nova::db::postgresql(
  $password,
  $dbname = 'nova',
  $user   = 'nova'
) {

  require 'postgresql::python'

  Postgresql::Server::Db[$dbname] -> Anchor<| title == 'nova-start' |>
  Postgresql::Server::Db[$dbname] ~> Exec<| title == 'nova-db-sync' |>
  Package['python-psycopg2'] -> Exec<| title == 'nova-db-sync' |>

  postgresql::server::db { $dbname:
    user     => $user,
    password => $password,
  }

}
