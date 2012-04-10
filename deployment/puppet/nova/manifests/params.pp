# these parameters need to be accessed from several locations and
# should be considered to be constant
class nova::params {

  case $::osfamily {
    'RedHat': {
      # package names
      $api_package_name         = false
      $cert_package_name        = false
      $common_package_name      = 'openstack-nova'
      $compute_package_name     = false
      $doc_package_name         = 'openstack-nova-doc'
      $network_package_name     = false
      $objectstore_package_name = false
      $scheduler_package_name   = false
      $volume_package_name      = false
      $vncproxy_package_name    = false
      # service names
      $api_service_name         = 'openstack-nova-api'
      $cert_service_name        = 'openstack-nova-cert'
      $compute_service_name     = 'openstack-nova-compute'
      $network_service_name     = 'openstack-nova-network'
      $objectstore_service_name = 'openstack-nova-objectstore'
      $scheduler_service_name   = 'openstack-nova-scheduler'
      $volume_service_name      = 'openstack-nova-volume'
      $libvirt_package_name     = 'libvirt'
      $libvirt_service_name     = 'libvirtd'
      $special_service_provider = 'init'
      # redhat specific config defaults
      $root_helper              = 'sudo nova-rootwrap'
    }
    'Debian': {
      # package names
      $api_package_name         = 'nova-api'
      $cert_package_name        = 'nova-cert'
      $common_package_name      = 'nova-common'
      $compute_package_name     = 'nova-compute'
      $doc_package_name         = 'nova-doc'
      $network_package_name     = 'nova-network'
      $objectstore_package_name = 'nova-objectstore'
      $scheduler_package_name   = 'nova-scheduler'
      $volume_package_name      = 'nova-volume'
      $vncproxy_package_name    = 'nova-vncproxy'
      # service names
      $api_service_name         = 'nova-api'
      $cert_service_name        = 'nova-cert'
      $compute_service_name     = 'nova-compute'
      $network_service_name     = 'nova-network'
      $objectstore_service_name = 'nova-objectstore'
      $scheduler_service_name   = 'nova-scheduler'
      $volume_service_name      = 'nova-volume'
      $libvirt_package_name     = 'libvirt-bin'
      $libvirt_service_name     = 'libvirt-bin'
      # some of the services need to be started form the special upstart provider
      $special_service_provider = 'upstart'
      # debian specific nova config
      $root_helper              = 'sudo nova-rootwrap'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

}
