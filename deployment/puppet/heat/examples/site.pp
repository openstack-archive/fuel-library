node default {
  Exec {
    path => ['/usr/bin', '/bin', '/usr/sbin', '/sbin']
  }

  # First, install a mysql server
  class { 'mysql::server': }

  # And create the database
  class { 'heat::db::mysql':
    password => 'heat',
  }

  # Common class
  class { 'heat':
    # The keystone_password parameter is mandatory
    keystone_password => 'password',
    sql_connection    => 'mysql://heat:heat@localhost/heat'
  }

  # Install heat-engine
  class { 'heat::engine':
    auth_encryption_key => 'whatever-key-you-like',
  }

  # Install the heat-api service
  class { 'heat::api': }

}
