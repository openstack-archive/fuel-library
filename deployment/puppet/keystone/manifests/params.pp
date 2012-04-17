#
# This class contains the platform differences for keystone
#
class keystone::params {
  case $::osfamily {
    'Debian': {
      $package_name     = 'keystone'
      $service_name     = 'keystone'
      case $::operatingsystem {
        'Debian': {
          $service_provider = undef
        }
        default: {
          $service_provider = 'upstart'
        }
      }
    }
    'RedHat': {
      $package_name     = 'openstack-keystone'
      $service_name     = 'openstack-keystone'
      $service_provider = undef
    }
  }
}
