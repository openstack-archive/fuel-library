#
class neutron::db::mysql (
  $password,
  $dbname        = 'neutron',
  $user          = 'neutron',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'latin1',
  $cluster_id    = 'localzone'
) {

  Class['mysql::server'] -> Class['neutron::db::mysql']

  if $::osfamily=="Debian"{
    Class['neutron::db::mysql']->Package['neutron-server']
  }

  require 'mysql::python'

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => $charset,
    require      => Class['mysql::server'],
  }

  if $allowed_hosts {
     neutron::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }

}
