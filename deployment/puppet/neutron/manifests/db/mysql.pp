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
  $cluster_id    = 'localzone'
) {

  Class['mysql::server'] -> Class['neutron::db::mysql']

  if $::osfamily=="Debian"{
    Class['neutron::db::mysql']->Package['neutron-server']
  }

  if ($mysql_module >= '2.2') {
    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      collate      => $collate,
      require      => Class['mysql::server'],
    }
  } else {
    require 'mysql::python'

    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      require      => Class['mysql::config'],
    }
  }


  if $allowed_hosts {
     neutron::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }

}
