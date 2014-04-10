#
# I should change this to mysql
# for consistency
#
class glance::db::mysql(
  $password,
  $dbname        = 'glance',
  $user          = 'glance',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'utf8',
  $collate       = 'utf8_unicode_ci',
  $mysql_module  = '0.9',
  $cluster_id    = 'localzone'
) {

  Class['mysql::server']     -> Class['glance::db::mysql']
  case $::osfamily {
    "Debian":
      {
        Class['glance::db::mysql'] -> Package['glance-registry']
      }
  }
  Class['glance::db::mysql'] -> Exec<| title == 'glance-manage db_sync' |>

  if ($mysql_module >= '2.2') {
    require 'mysql::bindings'
    require 'mysql::bindings::python'
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
    require 'mysql::python'
    Database[$dbname] ~> Exec<| title == 'glance-manage db_sync' |>

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
     glance::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }
}
