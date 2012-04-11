#
# This class contains the platform differences for keystone
#
class keystone::params {
  case $::osfamily {
    'Debian': {
      $package_name     = 'keystone'
      $service_provider = 'upstart'
    }
    'RedHat': {
      $package_name     = 'openstack-keystone'
      $service_provider = undef
    }
  }
}
