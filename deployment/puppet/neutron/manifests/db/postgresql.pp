# == Class: neutron::db::postgresql
#
# Class that configures postgresql for neutron
# Requires the Puppetlabs postgresql module.
#
# === Parameters
#
# [*password*]
#   (Required) Password to connect to the database.
#
# [*dbname*]
#   (Optional) Name of the database.
#   Defaults to 'neutron'.
#
# [*user*]
#   (Optional) User to connect to the database.
#   Defaults to 'neutron'.
#
#  [*encoding*]
#    (Optional) The charset to use for the database.
#    Default to undef.
#
#  [*privileges*]
#    (Optional) Privileges given to the database user.
#    Default to 'ALL'
#
class neutron::db::postgresql(
  $password,
  $dbname     = 'neutron',
  $user       = 'neutron',
  $encoding   = undef,
  $privileges = 'ALL',
) {

  ::openstacklib::db::postgresql { 'neutron':
    password_hash => postgresql_password($user, $password),
    dbname        => $dbname,
    user          => $user,
    encoding      => $encoding,
    privileges    => $privileges,
  }

  ::Openstacklib::Db::Postgresql['neutron'] ~> Service <| title == 'neutron-server' |>
  ::Openstacklib::Db::Postgresql['neutron'] ~> Exec <| title == 'neutron-db-sync' |>
}
