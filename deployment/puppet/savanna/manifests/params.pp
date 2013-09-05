class savanna::params {

  case $::osfamily {
    'RedHat': {
      # package names
      $savanna_package_name = 'openstack-savanna-virtualenv-savanna'
      # service names
      $savanna_service_name = 'openstack-savanna-api'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: \
${::operatingsystem}, module ${module_name} only support osfamily \
RedHat")
    }
  }
}
