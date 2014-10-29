#
# implements mysql backend for keystone
#
# This class can be used to create tables, users and grant
# privelege for a mysql keystone database.
#
# == parameters
#
# [password] Password that will be used for the keystone db user.
#   Optional. Defaults to: 'keystone_default_password'
#
# [dbname] Name of keystone database. Optional. Defaults to keystone.
#
# [user] Name of keystone user. Optional. Defaults to keystone.
#
# [host] Host where user should be allowed all priveleges for database.
# Optional. Defaults to 127.0.0.1.
#
# [allowed_hosts] Hosts allowed to use the database
#
#   [*mysql_module*]
#   (optional) The mysql puppet module version to use
#   Tested versions include 0.9 and 2.2
#   Default to '0.9'
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
  $password,
  $dbname        = 'keystone',
  $user          = 'keystone',
  $host          = '127.0.0.1',
  $charset       = 'utf8',
  $collate       = 'utf8_unicode_ci',
  $mysql_module  = '0.9',
  $allowed_hosts = undef
) {

  Class['keystone::db::mysql'] -> Exec<| title == 'keystone-manage db_sync' |>
  Class['keystone::db::mysql'] -> Service<| title == 'keystone' |>
  Mysql::Db[$dbname] ~> Exec<| title == 'keystone-manage db_sync' |>

  if ($mysql_module >= 2.2) {
    mysql::db { $dbname:
      user     => $user,
      password => $password,
      host     => $host,
      charset  => $charset,
      collate  => $collate,
      require  => Service['mysqld'],
    }
  } else {
    require mysql::python

    mysql::db { $dbname:
      user     => $user,
      password => $password,
      host     => $host,
      charset  => $charset,
      require  => Class['mysql::config'],
    }
  }

  # Check allowed_hosts to avoid duplicate resource declarations
  if is_array($allowed_hosts) and delete($allowed_hosts,$host) != [] {
    $real_allowed_hosts = delete($allowed_hosts,$host)
  } elsif is_string($allowed_hosts) and ($allowed_hosts != $host) {
    $real_allowed_hosts = $allowed_hosts
  }

  if $real_allowed_hosts {
    keystone::db::mysql::host_access { $real_allowed_hosts:
      user          => $user,
      password      => $password,
      database      => $dbname,
      mysql_module  => $mysql_module,
    }

    Keystone::Db::Mysql::Host_access[$real_allowed_hosts] -> Exec<| title == 'keystone-manage db_sync' |>

  }

}
