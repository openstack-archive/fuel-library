# The glance::db::mysql class creates a MySQL database for glance.
# It must be used on the MySQL server
#
# == Parameters
#
#  [*password*]
#    password to connect to the database. Mandatory.
#
#  [*dbname*]
#    name of the database. Optional. Defaults to glance.
#
#  [*user*]
#    user to connect to the database. Optional. Defaults to glance.
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
#  === Deprecated parameters:
#
#  [*cluster_id*] This parameter does nothing
#
class glance::db::mysql(
  $password,
  $dbname        = 'glance',
  $user          = 'glance',
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

  # TODO (degorenko): This workaround should be removed after mysql module upgrade 
  if ($mysql_module >= 2.2) {
    ::openstacklib::db::mysql { 'glance':
      user          => $user,
      password_hash => mysql_password($password),
      dbname        => $dbname,
      host          => $host,
      charset       => $charset,
      collate       => $collate,
      allowed_hosts => $allowed_hosts,
    }

    ::Openstacklib::Db::Mysql['glance'] ~> Exec<| title == 'glance-manage db_sync' |>
  }
  else {
    Class['glance::db::mysql'] -> Exec<| title == 'glance-manage db_sync' |>
    require mysql::python
    Database[$dbname] ~> Exec<| title == 'glance-manage db_sync' |>

    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      require      => Class['mysql::config'],
    }

    # Check allowed_hosts to avoid duplicate resource declarations
    # If $host in $allowed_hosts, then remove it
    if is_array($allowed_hosts) and delete($allowed_hosts,$host) != [] {
      $real_allowed_hosts = delete($allowed_hosts,$host)
    # If $host = $allowed_hosts, then set it to undef
    } elsif is_string($allowed_hosts) and ($allowed_hosts != $host) {
      $real_allowed_hosts = $allowed_hosts
    }

    if $real_allowed_hosts {
      # TODO this class should be in the mysql namespace
      glance::db::mysql::host_access { $real_allowed_hosts:
        user          => $user,
        password      => $password,
        database      => $dbname,
        mysql_module  => $mysql_module,
      }
    }
  }

}
