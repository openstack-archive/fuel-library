#
class cinder::db::mysql (
  $password,
  $dbname        = 'cinder',
  $user          = 'cinder',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'utf8',
  $collate       = 'utf8_unicode_ci',
  $mysql_module  = '0.9',
  $cluster_id    = 'localzone'
) {

  include cinder::params

  Class['mysql::server'] -> Class['cinder::db::mysql']
  if $::osfamily == "Debian" {
    Class['cinder::db::mysql'] -> Package['cinder-api']
  }
  Class['cinder::db::mysql'] -> Exec<| title == 'cinder-manage db_sync' |>

  Class['cinder::db::mysql'] -> Service<| title == 'cinder-scheduler' |>
  Class['cinder::db::mysql'] -> Service<| title == 'cinder-volume' |>
  Class['cinder::db::mysql'] -> Service<| title == 'cinder-api' |>

  if ($mysql_module >= '2.2') {
    Mysql_database[$dbname] ~> Exec<| title == 'cinder-manage db_sync' |>
    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      collate      => $collate,
      require      => Class['mysql::server'],
    }
  } else {
    Database[$dbname] ~> Exec<| title == 'cinder-manage db_sync' |>
    mysql::db { $dbname:
      user         => $user,
      password     => $password,
      host         => $host,
      charset      => $charset,
      require      => Class['mysql::server'],
    }
  }

  if $allowed_hosts {
     # TODO this class should be in the mysql namespace
     cinder::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }

}
