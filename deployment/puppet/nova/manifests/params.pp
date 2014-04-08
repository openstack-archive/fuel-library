# these parameters need to be accessed from several locations and
# should be considered to be constant
class nova::params {


  case $::osfamily {
    'RedHat': {
      # package names
      $libvirt_type_kvm         = $::operatingsystem ? {
                                    redhat =>  'qemu-kvm-rhev',
                                    default => 'qemu-kvm',
                                  }
      $guestmount_package_name  = 'libguestfs-tools-c'
      $api_package_name         = 'openstack-nova-api'
      $cert_package_name        = 'openstack-nova-cert'
      $common_package_name      = 'openstack-nova-common'
      $compute_package_name     = 'openstack-nova-compute'
      $conductor_package_name   = 'openstack-nova-conductor'
      $consoleauth_package_name = 'openstack-nova-console'
      $doc_package_name         = 'openstack-nova-doc'
      $libvirt_package_name     = 'libvirt'
      $network_package_name     = 'openstack-nova-network'
      $numpy_package_name       = 'numpy'
      $objectstore_package_name = 'openstack-nova-objectstore'
      $scheduler_package_name   = 'openstack-nova-scheduler'
      $tgt_package_name         = 'scsi-target-utils'
      $volume_package_name      = 'openstack-nova-volume'
      $meta_api_package_name    = 'openstack-nova-api'
      $vncproxy_package_name    = ['novnc','openstack-nova-novncproxy']
      $pymemcache_package_name  = 'python-memcached'
      # service names
      $api_service_name         = 'openstack-nova-api'
      $cert_service_name        = 'openstack-nova-cert'
      $compute_service_name     = 'openstack-nova-compute'
      $conductor_service_name   = 'openstack-nova-conductor'
      $consoleauth_service_name = 'openstack-nova-consoleauth'
      $console_service_name	= 'openstack-nova-console'
      $libvirt_service_name     = 'libvirtd'
      $network_service_name     = 'openstack-nova-network'
      $objectstore_service_name = 'openstack-nova-objectstore'
      $scheduler_service_name   = 'openstack-nova-scheduler'
      $tgt_service_name         = 'tgtd'
      $vncproxy_service_name    = 'openstack-nova-novncproxy'
      $volume_service_name      = 'openstack-nova-volume'
      $meta_api_service_name    = 'openstack-nova-metadata-api'
      $special_service_provider = 'init'
      # redhat specific config defaults
      $python_path		= 'python2.6/site-packages'
      $root_helper              = 'sudo nova-rootwrap'
      $lock_path                = '/var/lib/nova/tmp'
    }
    'Debian': {
      # package names
      $libvirt_type_kvm         = 'qemu-kvm'
      $guestmount_package_name  = 'guestmount'
      $api_package_name         = 'nova-api'
      $cert_package_name        = 'nova-cert'
      $common_package_name      = 'nova-common'
      $compute_package_name     = 'nova-compute'
      $conductor_package_name   = 'nova-conductor'
      $doc_package_name         = 'nova-doc'
      $libvirt_package_name     = 'libvirt-bin'
      $network_package_name     = 'nova-network'
      $vncproxy_package_name    = ['novnc', 'nova-novncproxy']
      $numpy_package_name       = 'python-numpy'
      $objectstore_package_name = 'nova-objectstore'
      $scheduler_package_name   = 'nova-scheduler'
      $tgt_package_name         = 'tgt'
      $volume_package_name      = 'nova-volume'
      $meta_api_package_name    = 'nova-api-metadata'
      $pymemcache_package_name  = 'python-memcache'
      # service names
      $api_service_name         = 'nova-api'
      $cert_service_name        = 'nova-cert'
      $compute_service_name     = 'nova-compute'
      $conductor_service_name   = 'nova-conductor'
      $consoleauth_service_name = 'nova-consoleauth'
      $console_service_name	= 'nova-console'
      $libvirt_service_name     = 'libvirt-bin'
      $network_service_name     = 'nova-network'
      $vncproxy_service_name    = 'nova-novncproxy'
      $objectstore_service_name = 'nova-objectstore'
      $scheduler_service_name   = 'nova-scheduler'
      $volume_service_name      = 'nova-volume'
      $meta_api_service_name    = 'nova-api-metadata'
      $tgt_service_name         = 'tgt'
      # debian specific nova config
      $python_path		= 'python2.7/dist-packages'
      $root_helper              = 'sudo nova-rootwrap'
      $lock_path                = '/var/lock/nova'
      case $::operatingsystem {
        'Debian': {
          $consoleauth_package_name = 'nova-console'
          # Use default provider on Debian
          $special_service_provider = undef
        }
        default: {
          $consoleauth_package_name = 'nova-consoleauth'
          # some of the services need to be started form the special upstart provider
          $special_service_provider = 'upstart'
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

}
