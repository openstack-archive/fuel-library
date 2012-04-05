#
# implements mysql backend for keystone
#
class keystone::mysql(
  $password,
  $dbname        = 'keystone',
  $user          = 'keystone_admin',
  $host          = '127.0.0.1',
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

}
