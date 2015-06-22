# == Class: keystone::db::postgresql
#
# Class that configures postgresql for keystone
# Requires the Puppetlabs postgresql module.
#
# == Authors
#
#   Stackforge Contributors puppet-openstack@puppetlabs.com
#   Etienne Pelletier epelletier@morphlabs.com
#
# == Copyright
#
# Copyright 2013-2014 Stackforge Contributors
# Copyright 2012 Etienne Pelletier, unless otherwise noted.
#
# === Parameters
#
# [*password*]
#   (Required) Password to connect to the database.
#
# [*dbname*]
#   (Optional) Name of the database.
#   Defaults to 'keystone'.
#
# [*user*]
#   (Optional) User to connect to the database.
#   Defaults to 'keystone'.
#
#  [*encoding*]
#    (Optional) The charset to use for the database.
#    Default to undef.
#
#  [*privileges*]
#    (Optional) Privileges given to the database user.
#    Default to 'ALL'
#
class keystone::db::postgresql(
  $password,
  $dbname     = 'keystone',
  $user       = 'keystone',
  $encoding   = undef,
  $privileges = 'ALL',
) {

  Class['keystone::db::postgresql'] -> Service<| title == 'keystone' |>

  ::openstacklib::db::postgresql { 'keystone':
    password_hash => postgresql_password($user, $password),
    dbname        => $dbname,
    user          => $user,
    encoding      => $encoding,
    privileges    => $privileges,
  }

  ::Openstacklib::Db::Postgresql['keystone'] ~> Exec<| title == 'keystone-manage db_sync' |>

}
