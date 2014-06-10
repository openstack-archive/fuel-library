#
# I should change this to mysql
# for consistency
#
#   [*mysql_module*]
#   (optional) The mysql puppet module version to use. Tested
#   versions include 0.9 and 2.2
#   Default to '0.9'
#
class glance::db::mysql(
  $password,
  $dbname        = 'glance',
  $user          = 'glance',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'utf8',
  $collate       = 'utf8_unicode_ci',
  $cluster_id    = 'localzone',
  $mysql_module  = '0.9'
) {

  Class['glance::db::mysql'] -> Exec<| title == 'glance-manage db_sync' |>

  if ($mysql_module >= 2.2) {
    require mysql::bindings
    require mysql::bindings::python
    Mysql_database[$dbname] ~> Exec<| title == 'glance-manage db_sync' |>

    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      collate      => $collate,
      require      => Class['mysql::server'],
    }

  } else {
    require mysql::python
    Database[$dbname] ~> Exec<| title == 'glance-manage db_sync' |>

    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      require      => Class['mysql::config'],
    }
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
