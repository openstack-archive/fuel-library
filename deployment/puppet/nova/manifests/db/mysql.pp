#
# Class that configures mysql for nova
#
class nova::db::mysql(
  $password,
  $dbname        = 'nova',
  $user          = 'nova',
  $host          = '127.0.0.1',
  $charset       = 'latin1',
  $allowed_hosts = undef,
  $cluster_id    = 'localzone'
) {

  require 'mysql::python'
  # Create the db instance before openstack-nova if its installed
  Mysql::Db[$dbname] -> Anchor<| title == 'nova-start' |>
  Mysql::Db[$dbname] ~> Exec<| title == 'nova-db-sync' |>

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => $charset,
    require      => Class['mysql::config'],
  }

  # Check allowed_hosts to avoid duplicate resource declarations
  if is_array($allowed_hosts) and delete($allowed_hosts,$host) != [] {
    $real_allowed_hosts = delete($allowed_hosts,$host)
  } elsif is_string($allowed_hosts) and ($allowed_hosts != $host) {
    $real_allowed_hosts = $allowed_hosts
  }

  if $real_allowed_hosts {
    nova::db::mysql::host_access { $real_allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }
}
