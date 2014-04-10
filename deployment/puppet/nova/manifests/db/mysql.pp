#
# Class that configures mysql for nova
#
class nova::db::mysql(
  $password,
  $dbname         = 'nova',
  $user           = 'nova',
  $host           = '127.0.0.1',
  $allowed_hosts  = undef,
  $cluster_id     = 'localzone',
  $charset        = 'utf8',
  $collate        = 'utf8_unicode_ci',
  $mysql_module   = '0.9',
) {

  include 'nova::params'

  # Create the db instance before openstack-nova if its installed
  Mysql::Db[$dbname] -> Anchor<| title == "nova-start" |>
  Mysql::Db[$dbname] ~> Exec<| title == 'nova-db-sync' |>

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
      require      => Class['mysql::server'],
    }
  }

  if $allowed_hosts {
    nova::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  } else {
    Nova::Db::Mysql::Host_access<<| tag == "${::deployment_id}::${::environment}" and tag == $cluster_id |>>
  }
}
