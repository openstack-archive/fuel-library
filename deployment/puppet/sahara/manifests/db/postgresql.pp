# == Class: sahara::db::postgresql
#
# The sahara::db::postgresql creates a PostgreSQL database for sahara.
# It must be used on the PostgreSQL server.
#
# === Parameters
#
# [*password*]
#   (Required) Password to connect to the database.
#
# [*dbname*]
#   (Optional) Name of the database.
#   Defaults to 'sahara'.
#
# [*user*]
#   (Optional) User to connect to the database.
#   Defaults to 'sahara'.
#
#  [*encoding*]
#    (Optional) The charset to use for the database.
#    Default to undef.
#
#  [*privileges*]
#    (Optional) Privileges given to the database user.
#    Default to 'ALL'
#
class sahara::db::postgresql(
  $password,
  $dbname     = 'sahara',
  $user       = 'sahara',
  $encoding   = undef,
  $privileges = 'ALL',
) {

  Class['sahara::db::postgresql'] -> Service<| title == 'sahara' |>

  ::openstacklib::db::postgresql { 'sahara':
    password_hash => postgresql_password($user, $password),
    dbname        => $dbname,
    user          => $user,
    encoding      => $encoding,
    privileges    => $privileges,
  }

  ::Openstacklib::Db::Postgresql['sahara'] ~> Exec<| title == 'sahara-dbmanage' |>

}
