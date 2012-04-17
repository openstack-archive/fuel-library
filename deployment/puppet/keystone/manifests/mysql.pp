#
# implements mysql backend for keystone
#
# This class can be used to create tables, users and grant
# privelege for a mysql keystone database.
#
# [*Parameters*]
#
# [password] Password that will be used for the keystone db user.
#   Optional. Defaults to: 'keystone_default_password'
#
# [dbname] Name of keystone database. Optional. Defaults to keystone.
#
# [user] Name of keystone user. Optional. Defaults to keystone_admin.
#
# [host] Host where user should be allowed all priveleges for database.
# Optional. Defaults to 127.0.0.1.
#
# [allowed_hosts] TODO implement.
#
# == Dependencies
#   Class['mysql::server']
#
# == Examples
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone::mysql(
  $password      = 'keystone_default_password',
  $dbname        = 'keystone',
  $user          = 'keystone_admin',
  $host          = '127.0.0.1',
  $allowed_hosts = undef
) {

  Class['keystone::mysql'] -> Service<| title == 'keystone' |>

  require 'mysql::python'

  file { '/var/lib/keystone/keystone.db':
    ensure    => absent,
    subscribe => Package['keystone'],
    before    => Mysql::Db[$dbname],
  }

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    # TODO does it make sense to support other charsets?
    charset      => 'latin1',
    require      => Class['mysql::server'],
  }

  # this probably needs to happen more often than just when the db is
  # created
  exec { 'keystone-manage db_sync':
    path        => '/usr/bin',
    refreshonly => true,
    subscribe   => Mysql::Db[$dbname],
    require => File['/etc/keystone/keystone.conf'],
  }

}
