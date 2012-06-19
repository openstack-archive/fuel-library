# these parameters need to be accessed from several locations and
# should be considered to be constant
class horizon::params {

  case $::osfamily {
    'RedHat': {
      $http_service                = 'httpd'
      $package_name                = 'openstack-dashboard'
    }
    'Debian': {
      $http_service                = 'apache2'
      case $::operatingsystem {
        'Debian': {
            $package_name          = 'openstack-dashboard-apache'
        }
        default: {
            $package_name          = 'openstack-dashboard'
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
}
