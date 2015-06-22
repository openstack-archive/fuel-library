# == Class: nova::db::postgresql
#
# Class that configures postgresql for nova
# Requires the Puppetlabs postgresql module.
#
# === Parameters
#
# [*password*]
#   (Required) Password to connect to the database.
#
# [*dbname*]
#   (Optional) Name of the database.
#   Defaults to 'nova'.
#
# [*user*]
#   (Optional) User to connect to the database.
#   Defaults to 'nova'.
#
#  [*encoding*]
#    (Optional) The charset to use for the database.
#    Default to undef.
#
#  [*privileges*]
#    (Optional) Privileges given to the database user.
#    Default to 'ALL'
#
class nova::db::postgresql(
  $password,
  $dbname     = 'nova',
  $user       = 'nova',
  $encoding   = undef,
  $privileges = 'ALL',
) {

  ::openstacklib::db::postgresql { 'nova':
    password_hash => postgresql_password($user, $password),
    dbname        => $dbname,
    user          => $user,
    encoding      => $encoding,
    privileges    => $privileges,
  }

  ::Openstacklib::Db::Postgresql['nova'] ~> Exec<| title == 'nova-db-sync' |>
  ::Openstacklib::Db::Postgresql['nova'] -> Anchor<| title == 'nova-start' |>

}
