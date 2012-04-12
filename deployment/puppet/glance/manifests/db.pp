#
# I should change this to mysql
# for consistency
#
class glance::db(
  $password,
  $dbname = 'glance',
  $user = 'glance',
  $host = '127.0.0.1',
  $allowed_hosts = undef,
  $cluster_id = 'localzone'
) {

  Class['glance::db'] ~> Exec<| title == 'glance-manage db_sync' |>

  require 'mysql::python'

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => 'latin1',
    # I may want to inject some sql
    require      => Class['mysql::server'],
  }

  if $allowed_hosts {
     # TODO this class should be in the mysql namespace
     glance::db::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }
}
