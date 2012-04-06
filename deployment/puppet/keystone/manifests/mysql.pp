#
# implements mysql backend for keystone
#
class keystone::mysql(
  $password      = 'keystone_default_password',
  $dbname        = 'keystone',
  $user          = 'keystone_admin',
  $host          = '127.0.0.1',
  $allowed_hosts = undef
) {

  require mysql::python

  file { '/var/lib/keystone/keystone.db':
    ensure    => absent,
    subscribe => Package['keystone'],
    before    => Mysql::Db[$dbname],
  }

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => 'latin1',
    require      => Class['mysql::server'],
  }

  # this probably needs to happen more often than just when the db is
  # created
  exec { 'keystone-manage db_sync':
    path        => '/usr/bin',
    refreshonly => true,
    subscribe   => Mysql::Db[$dbname],
  }

}
