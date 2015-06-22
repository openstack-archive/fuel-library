# The keystone::db::mysql class implements mysql backend for keystone
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

  if $mysql_module {
    warning('The mysql_module parameter is deprecated. The latest 2.x mysql module will be used.')
  }

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
}
