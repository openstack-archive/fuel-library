class sahara::params {
  $package_name  = 'sahara'
  $service_name  = 'sahara-all'
  $settings_path = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py'
  $templates_dir = '/usr/share/sahara/templates'

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
