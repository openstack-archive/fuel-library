class sahara::params {
  # package names
  $sahara_package_name = 'sahara'
  # dashboard package
  $sahara_dashboard_package_name = 'sahara-dashboard'
  # service names
  $sahara_service_name = 'sahara-api'

  $settings_path       = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py'
  $default_url_string  = "SAHARA_URL = 'http://localhost:8386/v1.0'"

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
