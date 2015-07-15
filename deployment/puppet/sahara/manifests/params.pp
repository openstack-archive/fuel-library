# == Class: sahara::params
#
# Parameters for puppet-sahara
#
class sahara::params {
  $dbmanage_command    = 'sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head'
  $client_package_name = 'python-saharaclient'

  case $::osfamily {
    'RedHat': {
      $common_package_name = 'openstack-sahara-common'
      $all_package_name = 'openstack-sahara'
      $api_package_name = 'openstack-sahara-api'
      $engine_package_name = 'openstack-sahara-engine'
      $all_service_name = 'openstack-sahara-all'
      $api_service_name = 'openstack-sahara-api'
      $engine_service_name = 'openstack-sahara-engine'
    }
    'Debian': {
      $common_package_name = 'sahara-common'
      $all_package_name = 'sahara'
      $api_package_name = 'sahara-api'
      $engine_package_name = 'sahara-engine'
      $all_service_name = 'sahara'
      $api_service_name = 'sahara-api'
      $engine_service_name = 'sahara-engine'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}")
    }
  }
}
