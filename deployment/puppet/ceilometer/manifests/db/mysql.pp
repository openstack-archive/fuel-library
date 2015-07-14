# The ceilometer::db::mysql class creates a MySQL database for ceilometer.
# It must be used on the MySQL server
#
# == Parameters
#
#  [*password*]
#    password to connect to the database. Mandatory.
#
#  [*dbname*]
#    name of the database. Optional. Defaults to ceilometer.
#
#  [*user*]
#    user to connect to the database. Optional. Defaults to ceilometer.
#
#  [*host*]
#    the default source host user is allowed to connect from.
#    Optional. Defaults to 'localhost'
#
#  [*allowed_hosts*]
#    other hosts the user is allowd to connect from.
#    Optional. Defaults to undef.
#
#  [*charset*]
#    the database charset. Optional. Defaults to 'utf8'
#
#  [*collate*]
#    the database collation. Optional. Defaults to 'utf8_general_ci'
#
#  [*mysql_module*]
#    (optional) Deprecated. Does nothing.
#
class ceilometer::db::mysql(
  $password      = false,
  $dbname        = 'ceilometer',
  $user          = 'ceilometer',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'utf8',
  $collate       = 'utf8_general_ci',
  $mysql_module  = undef,
) {

  if $mysql_module {
    warning('The mysql_module parameter is deprecated. The latest 2.x mysql module will be used.')
  }

  validate_string($password)

  ::openstacklib::db::mysql { 'ceilometer':
    user          => $user,
    password_hash => mysql_password($password),
    dbname        => $dbname,
    host          => $host,
    charset       => $charset,
    collate       => $collate,
    allowed_hosts => $allowed_hosts,
  }

  ::Openstacklib::Db::Mysql['ceilometer'] ~> Exec<| title == 'ceilometer-dbsync' |>
}
