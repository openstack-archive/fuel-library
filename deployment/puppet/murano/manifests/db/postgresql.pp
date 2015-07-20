# == Class: murano::db::postgresql
#
# The murano::db::postgresql creates a PostgreSQL database for murano.
# It must be used on the PostgreSQL server.
#
# === Parameters
#
# [*password*]
#   (Required) Password to connect to the database.
#
# [*dbname*]
#   (Optional) Name of the database.
#   Defaults to 'murano'.
#
# [*user*]
#   (Optional) User to connect to the database.
#   Defaults to 'murano'.
#
#  [*encoding*]
#    (Optional) The charset to use for the database.
#    Default to undef.
#
#  [*privileges*]
#    (Optional) Privileges given to the database user.
#    Default to 'ALL'
#
class murano::db::postgresql(
  $password,
  $dbname     = 'murano',
  $user       = 'murano',
  $encoding   = undef,
  $privileges = 'ALL',
) {

  Class['murano::db::postgresql'] -> Service<| title == 'murano' |>

  ::openstacklib::db::postgresql { 'murano':
    password_hash => postgresql_password($user, $password),
    dbname        => $dbname,
    user          => $user,
    encoding      => $encoding,
    privileges    => $privileges,
  }

  ::Openstacklib::Db::Postgresql['murano'] ~> Exec<| title == 'murano-dbmanage' |>

}
