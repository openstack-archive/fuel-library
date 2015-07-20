# == Class: sahara::params
#
# Parameters for puppet-sahara
#
class sahara::params {
  $dbmanage_command    = 'sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head'
  $client_package_name = 'python-saharaclient'

  case $::osfamily {
    'RedHat': {
      $package_name = 'openstack-sahara'
      $service_name = 'openstack-sahara-all'
    }
    'Debian': {
      $package_name = 'sahara'
      $service_name = 'sahara'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}")
    }
  }
}
