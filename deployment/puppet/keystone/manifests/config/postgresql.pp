# Class used to configure keystone connection information
# for postgresql databases.
#
# [*Parameters*]
#
# [user] User keystone should use to connect to database. Optional. Defaults to keystone_admin
#
# [password] Password that keystone should use to connect to database.
#   Optional. Defaults to: 'keystone_default_password'
#
# [host] Host where keystone should connect to database.
# Optional. Defaults to 127.0.0.1.
#
# [dbname] Name of database that keystone should connect to. Optional. Defaults to keystone.
#
# [idle_timeout] TODO document
#
# [min_pool_size] TODO document
#
# [max_pool_size] TODO document
#
# [pool_timeout] TODO document
#
# == Dependencies
# == Examples
# == Authors
#
#   Etienne Pelletier epelletier@morphlabs.com
#
# == Copyright
#
# Copyright 2012 Etienne Pelletier, unless otherwise noted.
#
class keystone::config::postgresql(
  $user          = 'keystone_admin',
  $password      = 'keystone_default_password',
  $host          = '127.0.0.1',
  $dbname        = 'keystone',
  $idle_timeout  = '300',
  $min_pool_size = '5',
  $max_pool_size = '10',
  $pool_timeout  = '200'
) {

  keystone::config { 'postgresql':
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
