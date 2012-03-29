class keystone::params {
  case $::osfamily {
    'Debian': {
      $service_provider = 'upstart'
    }
    'RedHat': {
      $service_provider = undef	
    }
  }
}
