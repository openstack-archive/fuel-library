# == Class: ceilometer::db::postgresql
#
# Class that configures postgresql for ceilometer
# Requires the Puppetlabs postgresql module.
#
# === Parameters
#
# [*password*]
#   (Required) Password to connect to the database.
#
# [*dbname*]
#   (Optional) Name of the database.
#   Defaults to 'ceilometer'.
#
# [*user*]
#   (Optional) User to connect to the database.
#   Defaults to 'ceilometer'.
#
#  [*encoding*]
#    (Optional) The charset to use for the database.
#    Default to undef.
#
#  [*privileges*]
#    (Optional) Privileges given to the database user.
#    Default to 'ALL'
#
class ceilometer::db::postgresql(
  $password,
  $dbname     = 'ceilometer',
  $user       = 'ceilometer',
  $encoding   = undef,
  $privileges = 'ALL',
) {

  ::openstacklib::db::postgresql { 'ceilometer':
    password_hash => postgresql_password($user, $password),
    dbname        => $dbname,
    user          => $user,
    encoding      => $encoding,
    privileges    => $privileges,
  }

  ::Openstacklib::Db::Postgresql['ceilometer']    ~> Exec<| title == 'ceilometer-dbsync' |>

}
