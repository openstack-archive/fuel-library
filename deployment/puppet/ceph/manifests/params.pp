#These are per-OS parameters and should be considered static
class ceph::params {

  case $::osfamily {
    'RedHat': {
      $service_cinder_volume      = 'openstack-cinder-volume'
      $service_cinder_volume_opts = '/etc/sysconfig/openstack-cinder-volume'
      $service_glance_api         = 'openstack-glance-api'
      $service_glance_registry    = 'openstack-glance-registry'
      $service_nova_compute       = 'openstack-nova-compute'

      package { ['ceph', 'redhat-lsb-core','ceph-deploy', 'pushy',]:
        ensure => latest,
      }
      file {'/etc/sudoers.d/ceph':
        content => "#This is required for ceph-deploy\nDefaults !requiretty\n"
      }
    }
    'Debian': {
      $service_cinder_volume      = 'cinder-volume'
      $service_cinder_volume_opts = '/etc/init/cinder-volume.conf'
      $servic_glance_api          = 'glance-api'
      $service_glance_registry    = 'glance-registry'
      $service_nova_compute       = 'nova-compute'

      package { ['ceph','ceph-deploy', 'pushy', ]:
        ensure => latest,
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
}