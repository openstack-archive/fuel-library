#
# implements mysql backend for keystone
#
# This class can be used to create tables, users and grant
# privelege for a mysql keystone database.
#
# == parameters
#
# [*password*]
#   (Mandatory) Password to connect to the database.
#   Defaults to 'false'.
#
# [*dbname*]
#   (Optional) Name of the database.
#   Defaults to 'keystone'.
#
# [*user*]
#   (Optional) User to connect to the database.
#   Defaults to 'keystone'.
#
# [*host*]
#   (Optional) The default source host user is allowed to connect from.
#   Defaults to '127.0.0.1'
#
# [*allowed_hosts*]
#   (Optional) Other hosts the user is allowed to connect from.
#   Defaults to 'undef'.
#
# [*charset*]
#   (Optional) The database charset.
#   Defaults to 'utf8'
#
# [*collate*]
#   (Optional) The database collate.
#   Only used with mysql modules >= 2.2.
#   Defaults to 'utf8_general_ci'
#
# === Deprecated Parameters
#
# [*mysql_module*]
#   (Optional) Does nothing.
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
  $collate       = 'utf8_general_ci',
  $mysql_module  = undef,
  $allowed_hosts = undef
) {

  if ($mysql_module >= 2.2) {
  validate_string($password)

  ::openstacklib::db::mysql { 'keystone':
    user          => $user,
    password_hash => mysql_password($password),
    dbname        => $dbname,
    host          => $host,
    charset       => $charset,
    collate       => $collate,
    allowed_hosts => $allowed_hosts,
   }

  ::Openstacklib::Db::Mysql['keystone'] ~> Exec<| title == 'keystone-manage db_sync' |>

  } else {

    Class['keystone::db::mysql'] -> Exec<| title == 'keystone-manage db_sync' |>
    Class['keystone::db::mysql'] -> Service<| title == 'keystone' |>
    Mysql::Db[$dbname] ~> Exec<| title == 'keystone-manage db_sync' |>

    require mysql::python

    mysql::db { $dbname:
      user     => $user,
      password => $password,
      host     => $host,
      charset  => $charset,
      require  => Class['mysql::config'],
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

}
