# these parameters need to be accessed from several locations and
# should be considered to be constant
class glance::params {

  $client_package_name = 'python-glanceclient'

  $cache_cleaner_command = 'glance-cache-cleaner'
  $cache_pruner_command  = 'glance-cache-pruner'

  case $::osfamily {
    'RedHat': {
      $api_package_name      = 'openstack-glance'
      $registry_package_name = 'openstack-glance'
      $api_service_name      = 'openstack-glance-api'
      $registry_service_name = 'openstack-glance-registry'
      $db_sync_command       = 'glance-manage --config-file=/etc/glance/glance-registry.conf db_sync'
      if ($::operatingsystem != 'fedora' and versioncmp($::operatingsystemrelease, '7') < 0) {
        $pyceph_package_name = 'python-ceph'
      } else {
        $pyceph_package_name = 'python-rbd'
      }
    }
    'Debian': {
      $api_package_name      = 'glance-api'
      $registry_package_name = 'glance-registry'
      $api_service_name      = 'glance-api'
      $registry_service_name = 'glance-registry'
      $db_sync_command       = 'glance-manage --config-file=/etc/glance/glance-registry.conf db_sync'
      $pyceph_package_name   = 'python-ceph'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

}
