#
#   [*mysql_module*]
#   (optional) The mysql puppet module version to use. Tested versions
#   include 0.9 and 2.2
#   Default to '0.9'
#
class neutron::db::mysql (
  $password,
  $dbname        = 'neutron',
  $user          = 'neutron',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'utf8',
  $collate       = 'utf8_unicode_ci',
  $mysql_module  = '0.9',
  $cluster_id    = 'localzone',
  $sync_db       = 'false',
) {

  Class['mysql::server'] -> Class['neutron::db::mysql']
  if $::osfamily == "Debian" {
    Class['neutron::db::mysql'] -> Package['neutron-server']
  }

  if ($mysql_module >= 2.2) {
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

    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      require      => Class['mysql::server'],
    }
  }

  # Check allowed_hosts to avoid duplicate resource declarations
  if is_array($allowed_hosts) and delete($allowed_hosts,$host) != [] {
    $real_allowed_hosts = delete($allowed_hosts,$host)
  } elsif is_string($allowed_hosts) and ($allowed_hosts != $host) {
    $real_allowed_hosts = $allowed_hosts
  }

  if $sync_db {
    Mysql::Db[$dbname] -> Exec['neutron-db-sync']
  }

  if $real_allowed_hosts {
    neutron::db::mysql::host_access { $real_allowed_hosts:
      user          => $user,
      password      => $password,
      database      => $dbname,
      mysql_module  => $mysql_module,
    }
    if $sync_db {
      Neutron::Db::Mysql::Host_access[$real_allowed_hosts] -> Exec['neutron-db-sync']
    }
  }
}
