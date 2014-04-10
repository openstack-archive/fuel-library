# The heat::db::mysql class creates a MySQL database for heat.
# It must be used on the MySQL server
#
# == Parameters
#
#  [*password*]
#    password to connect to the database. Mandatory.
#
#  [*dbname*]
#    name of the database. Optional. Defaults to heat.
#
#  [*user*]
#    user to connect to the database. Optional. Defaults to heat.
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
#    the database collate. Optional. Only used with mysql modules
#    >=  2.2
#    Defaults to 'utf8_unicode_ci'
#
#  [*mysql_module*]
#    The version of the mysql puppet module to use.
#    Tested versions include 0.9 and 2.2
#    Defaults to '0.9'.
#
class heat::db::mysql(
  $password      = false,
  $dbname        = 'heat',
  $user          = 'heat',
  $host          = 'localhost',
  $allowed_hosts = undef,
  $charset       = 'utf8',
  $collate       = 'utf8_unicode_ci',
  $mysql_module  = '0.9'
) {

  validate_string($password)

  Class['heat::db::mysql'] -> Exec<| title == 'heat-manage db_sync' |>
  Mysql::Db[$dbname] ~> Exec<| title == 'heat-manage db_sync' |>

  if ($mysql_module >= 2.2) {
    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      collate      => $collate,
      require      => Service['mysqld'],
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
    heat::db::mysql::host_access { $real_allowed_hosts:
      user          => $user,
      password      => $password,
      database      => $dbname,
      mysql_module  => $mysql_module,
    }
  }
}
