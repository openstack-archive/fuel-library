# these parameters need to be accessed from several locations and
# should be considered to be constant
class glance::params {

  $client_package_name = 'python-glanceclient'
  $pyceph_package_name = 'python-ceph'

  $cache_cleaner_command = 'glance-cache-cleaner'
  $cache_pruner_command  = 'glance-cache-pruner'

  case $::osfamily {
    'RedHat': {
      $package_name          = 'openstack-glance'
      $api_service_name      = 'openstack-glance-api'
      $registry_service_name = 'openstack-glance-registry'
      $db_sync_command       = 'glance-manage db_sync'
    }
    'Debian': {
      $package_name          = 'glance'
      $api_service_name      = 'glance-api'
      $registry_service_name = 'glance-registry'
      $db_sync_command       = 'glance-manage db_sync'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

}
