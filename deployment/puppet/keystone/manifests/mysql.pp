#
# implements mysql backend for keystone
#
class keystone::mysql(
  $password,
  $dbname        = 'keystone',
  $user          = 'keystone_admin',
  $host          = '127.0.0.1',
  $idle_timeout  = '300',
  $min_pool_size = '5',
  $max_pool_size = '10',
  $pool_timeout  = '200',
  $allowed_hosts = undef
) {

  require mysql::python

  file { '/var/lib/keystone/keystone.db':
    ensure    => absent,
    subscribe => Package['keystone'],
    before    => Class['keystone::db'],
  }

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => 'latin1',
    require      => Class['mysql::server'],
  }

  keystone::config { 'sql': 
    config => {
      user          => $user,
      password      => $password,
      host          => $host,
      dbname        => $dbname,
      idle_timeout  => $idle_timeout,
      min_pool_size => $min_pool_size,
      max_pool_size => $max_pool_size,
      pool_timeout  => $pool_timeout
    },
    order  => '02',
  }
}
