node default {
  Exec {
    path => ['/usr/bin', '/bin', '/usr/sbin', '/sbin']
  }

  # First, install a mysql server
  class { '::mysql::server': }
  # And create the database
  class { '::ceilometer::db::mysql':
    password => 'ceilometer',
  }

  # Add the base ceilometer class & parameters
  # This class is required by ceilometer agents & api classes
  # The metering_secret parameter is mandatory
  class { '::ceilometer':
    metering_secret => 'darksecret'
  }

  # Configure the ceilometer database
  # Only needed if ceilometer::agent::central or ceilometer::api are declared
  class { '::ceilometer::db':
  }

  # Configure ceilometer database with mongodb

  # class { '::ceilometer::db':
  #   database_connection => 'mongodb://localhost:27017/ceilometer',
  #   require             => Class['mongodb'],
  # }

  # Install the ceilometer-api service
  # The keystone_password parameter is mandatory
  class { '::ceilometer::api':
    keystone_password => 'tralalayouyou'
  }

  # Set common auth parameters used by all agents (compute/central)
  class { '::ceilometer::agent::auth':
    auth_url      => 'http://localhost:35357/v2.0',
    auth_password => 'tralalerotralala'
  }

  # Install polling agent
  # Can be used instead of central, compute or ipmi agent
  # class { 'ceilometer::agent::polling':
  #   central_namespace => true,
  #   compute_namespace => false,
  #   ipmi_namespace    => false
  # }
  # class { 'ceilometer::agent::polling':
  #   central_namespace => false,
  #   compute_namespace => true,
  #   ipmi_namespace    => false
  # }
  # class { 'ceilometer::agent::polling':
  #   central_namespace => false,
  #   compute_namespace => false,
  #   ipmi_namespace    => true
  # }
  # As default use central and compute polling namespaces
  class { '::ceilometer::agent::polling':
    central_namespace => true,
    compute_namespace => true,
    ipmi_namespace    => false,
  }

  # Install compute agent (deprecated)
  # default: enable
  # class { 'ceilometer::agent::compute':
  # }

  # Install central agent (deprecated)
  # class { 'ceilometer::agent::central':
  # }

  # Install alarm notifier
  class { '::ceilometer::alarm::notifier':
  }

  # Install alarm evaluator
  class { '::ceilometer::alarm::evaluator':
  }

  # Purge 1 month old meters
  class { '::ceilometer::expirer':
    time_to_live => '2592000'
  }

  # Install notification agent
  class { '::ceilometer::agent::notification':
  }

}
