class sahara::params {
  $templates_dir = '/usr/share/sahara/templates'

  case $::osfamily {
    'RedHat': {
      $package_name  = 'openstack-sahara'
      $sahara_api_service_name  = 'openstack-sahara-api'
      $sahara_engine_service_name = 'openstack-sahara-engine'
  }
    'Debian': {
      $package_name  = 'sahara'
      $sahara_api_service_name  = 'sahara-api'
      $sahara_engine_service_name = 'sahara-engine'
  }
  default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: \
${::operatingsystem}, module ${module_name} only support osfamily \
RedHat and Debian")
    }
  }

}
