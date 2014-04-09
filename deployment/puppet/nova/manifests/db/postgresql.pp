#
# Class that configures postgresql for nova
#
# Requires the Puppetlabs postgresql module.
class nova::db::postgresql(
  $password,
  $dbname = 'nova',
  $user   = 'nova'
) {

  require 'postgresql::python'

  Postgresql::Db[$dbname] -> Anchor<| title == 'nova-start' |>
  Postgresql::Db[$dbname] ~> Exec<| title == 'nova-db-sync' |>
  Package['python-psycopg2'] -> Exec<| title == 'nova-db-sync' |>

  postgresql::db { $dbname:
    user     => $user,
    password => $password,
  }

}
