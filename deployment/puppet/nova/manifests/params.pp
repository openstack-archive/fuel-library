# == Class: nova::params
#
# These parameters need to be accessed from several locations and
# should be considered to be constant
class nova::params {

  case $::osfamily {
    'RedHat': {
      # package names
      $api_package_name             = 'openstack-nova-api'
      $cells_package_name           = 'openstack-nova-cells'
      $cert_package_name            = 'openstack-nova-cert'
      $common_package_name          = 'openstack-nova-common'
      $compute_package_name         = 'openstack-nova-compute'
      $conductor_package_name       = 'openstack-nova-conductor'
      $consoleauth_package_name     = 'openstack-nova-console'
      $doc_package_name             = 'openstack-nova-doc'
      $libvirt_package_name         = 'libvirt'
      $network_package_name         = 'openstack-nova-network'
      $numpy_package_name           = 'numpy'
      $objectstore_package_name     = 'openstack-nova-objectstore'
      $scheduler_package_name       = 'openstack-nova-scheduler'
      $tgt_package_name             = 'scsi-target-utils'
      $vncproxy_package_name        = 'openstack-nova-novncproxy'
      $spicehtml5proxy_package_name = 'openstack-nova-console'
      # service names
      $api_service_name             = 'openstack-nova-api'
      $cells_service_name           = 'openstack-nova-cells'
      $cert_service_name            = 'openstack-nova-cert'
      $compute_service_name         = 'openstack-nova-compute'
      $conductor_service_name       = 'openstack-nova-conductor'
      $consoleauth_service_name     = 'openstack-nova-consoleauth'
      $libvirt_service_name         = 'libvirtd'
      $network_service_name         = 'openstack-nova-network'
      $objectstore_service_name     = 'openstack-nova-objectstore'
      $scheduler_service_name       = 'openstack-nova-scheduler'
      $tgt_service_name             = 'tgtd'
      $vncproxy_service_name        = 'openstack-nova-novncproxy'
      $spicehtml5proxy_service_name = 'openstack-nova-spicehtml5proxy'
      # redhat specific config defaults
      $root_helper                  = 'sudo nova-rootwrap'
      $lock_path                    = '/var/lib/nova/tmp'
      case $::operatingsystem {
        'Fedora', 'RedHat': {
          $special_service_provider = undef
        }
        'RedHat': {
          if ($::operatingsystemrelease < 7) {
            $special_service_provider = 'init'
          } else {
            $special_service_provider = undef
          }
        }
        default: {
          $special_service_provider = 'init'
        }
      }
    }
    'Debian': {
      # package names
      $api_package_name             = 'nova-api'
      $cells_package_name           = 'nova-cells'
      $cert_package_name            = 'nova-cert'
      $common_package_name          = 'nova-common'
      $compute_package_name         = 'nova-compute'
      $conductor_package_name       = 'nova-conductor'
      $consoleauth_package_name     = 'nova-consoleauth'
      $doc_package_name             = 'nova-doc'
      $libvirt_package_name         = 'libvirt-bin'
      $network_package_name         = 'nova-network'
      $numpy_package_name           = 'python-numpy'
      $objectstore_package_name     = 'nova-objectstore'
      $scheduler_package_name       = 'nova-scheduler'
      $tgt_package_name             = 'tgt'
      # service names
      $api_service_name             = 'nova-api'
      $cells_service_name           = 'nova-cells'
      $cert_service_name            = 'nova-cert'
      $compute_service_name         = 'nova-compute'
      $conductor_service_name       = 'nova-conductor'
      $consoleauth_service_name     = 'nova-consoleauth'
      $libvirt_service_name         = 'libvirt-bin'
      $network_service_name         = 'nova-network'
      $objectstore_service_name     = 'nova-objectstore'
      $scheduler_service_name       = 'nova-scheduler'
      $spicehtml5proxy_service_name = 'nova-spicehtml5proxy'
      $vncproxy_service_name        = 'nova-novncproxy'
      $tgt_service_name             = 'tgt'
      # debian specific nova config
      $root_helper                  = 'sudo nova-rootwrap'
      $lock_path                    = '/var/lock/nova'
      case $::operatingsystem {
        'Debian': {
          $spicehtml5proxy_package_name = 'nova-consoleproxy'
          $vncproxy_package_name    = 'nova-consoleproxy'
          # Use default provider on Debian
          $special_service_provider = undef
        }
        default: {
          $spicehtml5proxy_package_name = 'nova-spiceproxy'
          $vncproxy_package_name    = 'nova-novncproxy'
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
