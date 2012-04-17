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
# [allowed_hosts] Hosts allowed to use the database
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
class keystone::db::mysql(
  $password      = 'keystone_default_password',
  $dbname        = 'keystone',
  $user          = 'keystone_admin',
  $host          = '127.0.0.1',
  $allowed_hosts = undef
) {

  Class['keystone::db::mysql'] -> Service<| title == 'keystone' |>

  require 'mysql::python'

  mysql::db { $dbname:
    user     => $user,
    password => $password,
    host     => $host,
    # TODO does it make sense to support other charsets?
    charset  => 'latin1',
    require  => Class['mysql::server'],
  }

  if $allowed_hosts {
    keystone::mysql::host_access { $allowed_hosts:
      user     => $user,
      password => $password,
      database => $dbname,
    }
  }


  Mysql::Db[$dbname] ~> Exec<| title == 'keystone-manage db_sync' |>

}
