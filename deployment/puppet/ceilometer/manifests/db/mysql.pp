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
#    the database charset. Optional. Defaults to 'latin1'
#
class ceilometer::db::mysql(
  $password      = false,
  $dbname        = 'ceilometer',
  $user          = 'ceilometer',
  $host          = 'localhost',
  $allowed_hosts = undef,
  $charset       = 'latin1',
) {

  validate_string($password)

  Class['mysql::server'] -> Class['ceilometer::db::mysql']
  Class['ceilometer::db::mysql'] -> Exec<| title == 'ceilometer-dbsync' |>
  Mysql::Db[$dbname] ~> Exec<| title == 'ceilometer-dbsync' |>

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => $charset,
    #require      => Class['mysql::config'],
    require      => Class['mysql::server'],
  }

  if $allowed_hosts {
    ceilometer::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }
}
