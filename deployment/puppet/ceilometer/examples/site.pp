node default {
  Exec {
    path => ['/usr/bin', '/bin', '/usr/sbin', '/sbin']
  }

  # First, install a mysql server
  class { 'mysql::server': }
  # And create the database
  class { 'ceilometer::db::mysql':
    password => 'ceilometer',
  }

  # Add the base ceilometer class & parameters
  # This class is required by ceilometer agents & api classes
  # The metering_secret parameter is mandatory
  class { 'ceilometer':
    metering_secret => 'darksecret'
  }

  # Configure the ceilometer database
  # Only needed if ceilometer::agent::central or ceilometer::api are declared
  class { 'ceilometer::db':
  }

  # Install the ceilometer-api service
  # The keystone_password parameter is mandatory
  class { 'ceilometer::api':
    keystone_password => 'tralalayouyou'
  }

  # Install compute agent
  class { 'ceilometer::agent::compute':
  }

  # Enable ceilometer agent notification service
  class { 'ceilometer::agent_notification':
  }

}
