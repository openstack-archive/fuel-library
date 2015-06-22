# == Class: ironic::db::postgresql
#
# Class that configures postgresql for ironic
# Requires the Puppetlabs postgresql module.
#
# === Parameters
#
# [*password*]
#   (Required) Password to connect to the database.
#
# [*dbname*]
#   (Optional) Name of the database.
#   Defaults to 'ironic'.
#
# [*user*]
#   (Optional) User to connect to the database.
#   Defaults to 'ironic'.
#
#  [*encoding*]
#    (Optional) The charset to use for the database.
#    Default to undef.
#
#  [*privileges*]
#    (Optional) Privileges given to the database user.
#    Default to 'ALL'
#
class ironic::db::postgresql(
  $password,
  $dbname     = 'ironic',
  $user       = 'ironic',
  $encoding   = undef,
  $privileges = 'ALL',
) {

  Class['ironic::db::postgresql'] -> Service<| title == 'ironic' |>

  ::openstacklib::db::postgresql { 'ironic':
    password_hash => postgresql_password($user, $password),
    dbname        => $dbname,
    user          => $user,
    encoding      => $encoding,
    privileges    => $privileges,
  }

  ::Openstacklib::Db::Postgresql['ironic'] ~> Exec<| title == 'ironic-dbsync' |>

}
