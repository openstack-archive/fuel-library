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
#  [*collate*]
#    the database collation. Optional. Defaults to 'latin1_swedish_ci'
#
#  [*mysql_module*]
#    (optional) Mysql module version to use. Tested versions
#    are 0.9 and 2.2
#    Defaults to '0.9'
#
class ceilometer::db::mysql(
  $password      = false,
  $dbname        = 'ceilometer',
  $user          = 'ceilometer',
  $host          = 'localhost',
  $allowed_hosts = undef,
  $charset       = 'latin1',
  $collate       = 'latin1_swedish_ci',
  $mysql_module  = '0.9',
) {

  validate_string($password)

  Class['mysql::server'] -> Class['ceilometer::db::mysql']
  Class['ceilometer::db::mysql'] -> Exec<| title == 'ceilometer-dbsync' |>
  Mysql::Db[$dbname] ~> Exec<| title == 'ceilometer-dbsync' |>

  if $mysql_module >= 2.2 {
    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      collate      => $collate,
      require      => Class['mysql::server'],
    }
  } else {
    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      require      => Class['mysql::config'],
    }
  }

  # Check allowed_hosts to avoid duplicate resource declarations
  if is_array($allowed_hosts) and delete($allowed_hosts,$host) != [] {
    $real_allowed_hosts = delete($allowed_hosts,$host)
  } elsif is_string($allowed_hosts) and ($allowed_hosts != $host) {
    $real_allowed_hosts = $allowed_hosts
  }

  if $real_allowed_hosts {
    ceilometer::db::mysql::host_access { $real_allowed_hosts:
      user         => $user,
      password     => $password,
      database     => $dbname,
      mysql_module => $mysql_module,
    }
  }
}
