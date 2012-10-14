# Class used to configure keystone connection information
# for mysql databases.
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
# [idle_timeout] The timeout before idle qdl connection are reaped.
#
# == Dependencies
# == Examples
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone::config::mysql(
  $user          = 'keystone_admin',
  $password      = 'keystone_default_password',
  $host          = '127.0.0.1',
  $dbname        = 'keystone',
  $idle_timeout  = '200',
#  the below key,values will not be read from the keystone.conf and should be removed
#  $min_pool_size = '5',
#  $max_pool_size = '10',
#  $pool_timeout  = '200'
) {

  keystone::config { 'mysql':
    config => {
      user          => $user,
      password      => $password,
      host          => $host,
      dbname        => $dbname,
      idle_timeout  => $idle_timeout,
#      min_pool_size => $min_pool_size,
#      max_pool_size => $max_pool_size,
#      pool_timeout  => $pool_timeout
    },
    order  => '02',
  }

}
