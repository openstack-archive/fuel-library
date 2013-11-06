class murano::params {

  # package names
  $murano_conductor_package_name      = 'murano-conductor'
  $murano_api_package_name            = 'murano-api'
  $murano_dashboard_package_name      = 'murano-dashboard'
  $murano_common_package_name         = 'murano-common'
  $murano_metadataclient_package_name = 'murano-metadataclient'
  $murano_repository_package_name     = 'murano-repository'
  $python_muranoclient_package_name   = 'python-muranoclient'
  
  $murano_dashboard_deps         = [ 'python-babel' ]

  # service names
  $murano_conductor_service_name  = 'openstack-murano-conductor'
  $murano_api_service_name        = 'openstack-murano-api'
  $murano_repository_service_name = 'openstack-murano-repository'
  
  $default_url_string           = "MURANO_API_URL = 'http://127.0.0.1:8082'"
  $default_metadata_url_string  = "MURANO_METADATA_URL = 'http://127.0.0.1:8084'"

  case $::osfamily {
    'RedHat': {
      $local_settings_path = '/etc/openstack-dashboard/local_settings'
    }
    'Debian': {
      $local_settings_path = '/etc/openstack-dashboard/local_settings.py'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

}
