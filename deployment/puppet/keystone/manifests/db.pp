class keystone::db(
  $password,
  $dbname = 'keystone',
  $user = 'keystone_admin',
  $host = '127.0.0.1',
  $allowed_hosts = undef
) {

  require mysql::python

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => 'latin1',
    require      => Class['mysql::server'],
  }
}
