class murano::params {

  case $::osfamily {
    'RedHat': {
      # package names
      $murano_conductor_package_name = 'openstack-murano-virtualenv-murano-conductor'
      $murano_api_package_name       = 'openstack-murano-virtualenv-murano-api'
      # service names
      $murano_conductor_service_name = 'openstack-murano-conductor'
      $murano_api_service_name       = 'openstack-murano-api'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: \
${::operatingsystem}, module ${module_name} only support osfamily \
RedHat")
    }
  }
}
