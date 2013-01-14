#
# implements postgresql backend for keystone
#
# This class can be used to create tables, users and grant
# privelege for a postgresql keystone database.
#
# Requires Puppetlabs Postgresql module.
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
#   Class['postgresql::server']
#
# == Examples
# == Authors
#
#   Etienne Pelletier epelletier@morphlabs.com
#
# == Copyright
#
# Copyright 2012 Etienne Pelletier, unless otherwise noted.
#
class keystone::db::postgresql(
  $password,
  $dbname        = 'keystone',
  $user          = 'keystone_admin',
) {

  Class['keystone::db::postgresql'] -> Package<| title == 'keystone' |>
  Class['keystone::db::postgresql'] -> Exec<| title == 'keystone-manage db_sync' |>
  #require 'postgresql::python'

   postgresql::db { "${dbname}":
      user     =>  "${user}",
      password  =>  "${password}",
   }

  Postgresql::Db[$dbname] ~> Exec<| title == 'keystone-manage db_sync' |>

}
