# The neutron::db::mysql class creates a MySQL database for neutron.
# It must be used on the MySQL server
#
# == Parameters
#
#  [*password*]
#    password to connect to the database. Mandatory.
#
#  [*dbname*]
#    name of the database. Optional. Defaults to neutron.
#
#  [*user*]
#    user to connect to the database. Optional. Defaults to neutron.
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
#   (optional) Deprecated. Does nothing.
#
class neutron::db::mysql (
  $password,
  $dbname        = 'neutron',
  $user          = 'neutron',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'utf8',
  $collate       = 'utf8_general_ci',
  $cluster_id    = 'localzone',
  $mysql_module  = undef,
) {

  if $mysql_module {
    warning('The mysql_module parameter is deprecated. The latest 2.x mysql module will be used.')
  }

  validate_string($password)

  if ($mysql_module >= 2.2) {
    ::openstacklib::db::mysql { 'neutron':
      user          => $user,
      password_hash => mysql_password($password),
      dbname        => $dbname,
      host          => $host,
      charset       => $charset,
      collate       => $collate,
      allowed_hosts => $allowed_hosts,
    }
    ::Openstacklib::Db::Mysql['neutron'] ~> Service <| title == 'neutron-server' |>
    ::Openstacklib::Db::Mysql['neutron'] ~> Exec <| title == 'neutron-db-sync' |>
  } else {
    require mysql::python

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
    neutron::db::mysql::host_access { $real_allowed_hosts:
      user          => $user,
      password      => $password,
      database      => $dbname,
      mysql_module  => $mysql_module,
    }
  }
}
