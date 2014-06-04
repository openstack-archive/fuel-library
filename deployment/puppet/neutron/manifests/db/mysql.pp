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

  exec {'upgrade neutron head':
         path    => ['/bin','/sbin','/usr/bin','/usr/sbin'],
         command => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
  }

  Mysql::Db[$dbname] -> Exec['upgrade neutron head']
  if $allowed_hosts {
     neutron::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
    Neutron::Db::Mysql::Host_access[$allowed_hosts] -> Exec['upgrade neutron head']
  }

}
