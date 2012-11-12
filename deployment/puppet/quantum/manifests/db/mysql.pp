#
class quantum::db::mysql (
  $password,
  $dbname        = 'quantum',
  $user          = 'quantum',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'latin1',
  $cluster_id    = 'localzone'
) {

  Class['mysql::server'] -> Class['quantum::db::mysql']

  require 'mysql::python'

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => $charset,
    require      => Class['mysql::config'],
  }

  if $allowed_hosts {
     quantum::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }

}
