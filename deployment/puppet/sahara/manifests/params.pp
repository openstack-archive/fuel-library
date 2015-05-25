class sahara::params {
  $templates_dir = '/usr/share/sahara/templates'

  case $::osfamily {
    'RedHat': {
      $sahara_common_package_name = 'openstack-sahara-common'
      $sahara_api_service_name  = 'openstack-sahara-api'
      $sahara_api_package_name  = 'openstack-sahara-api'
      $sahara_engine_service_name = 'openstack-sahara-engine'
      $sahara_engine_package_name = 'openstack-sahara-engine'
  }
    'Debian': {
      $sahara_common_package_name  = 'sahara-common'
      $sahara_api_service_name  = 'sahara-api'
      $sahara_api_package_name  = 'sahara-api'
      $sahara_engine_service_name = 'sahara-engine'
      $sahara_engine_package_name  = 'sahara-engine'
  }
  default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: \
${::operatingsystem}, module ${module_name} only support osfamily \
RedHat and Debian")
    }
  }

}
