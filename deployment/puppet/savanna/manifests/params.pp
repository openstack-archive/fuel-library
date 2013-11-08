class savanna::params {
  # package names
  $savanna_package_name = 'savanna'
  # dashboard package
  $savanna_dashboard_package_name = 'savanna-dashboard'
  # service names
  $savanna_service_name = 'savanna-api'

  $settings_path       = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py'
  $default_url_string  = "SAVANNA_URL = 'http://localhost:8386/v1.0'"

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
