#
# Class that configures mysql for nova
#
class nova::db::mysql(
  $password,
  $dbname = 'nova',
  $user = 'nova',
  $host = '127.0.0.1',
  $allowed_hosts = undef,
  $cluster_id = 'localzone'
) {

  include 'nova::params'

  require 'mysql::python'
  # Create the db instance before openstack-nova if its installed
  Mysql::Db[$dbname] -> Anchor<| title == "nova-start" |>
  Mysql::Db[$dbname] ~> Exec<| title == 'nova-db-sync' |>

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => $nova::params::nova_db_charset,
    # I may want to inject some sql
    require      => Class['mysql::config'],
  }

  if $allowed_hosts {
    nova::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  } else {
    Nova::Db::Mysql::Host_access<<| tag == $cluster_id |>>
  }
}
