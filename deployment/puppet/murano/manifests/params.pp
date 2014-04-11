class murano::params {

  # package names
  $murano_api_package_name            = 'murano-api'
  $murano_dashboard_package_name      = 'murano-dashboard'
  $python_muranoclient_package_name   = 'python-muranoclient'

  $murano_dashboard_deps         = [ 'python-babel' ]

  # service names
  $murano_api_service_name        = 'openstack-murano-api'

  $default_url_string           = "MURANO_API_URL = 'http://127.0.0.1:8082'"

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
