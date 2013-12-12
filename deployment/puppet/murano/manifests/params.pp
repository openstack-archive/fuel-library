class murano::params {

  # package names
  $conductor_package_name      = 'murano-conductor'
  $api_package_name            = 'murano-api'
  $common_package_name         = 'murano-common'
  $metadataclient_package_name = 'murano-metadataclient'
  $repository_package_name     = 'murano-repository'
  $muranoclient_package_name   = 'python-muranoclient'
  $dashboard_deps_name         = [ 'python-babel' ]
  $dashboard_package_name      = 'murano-dashboard'

  # service names
  $conductor_service_name  = 'openstack-murano-conductor'
  $api_service_name        = 'openstack-murano-api'
  $repository_service_name = 'openstack-murano-repository'
  
  $default_url_string = "MURANO_API_URL = 'http://127.0.0.1:8082'"
  $settings_path      = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py'

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
