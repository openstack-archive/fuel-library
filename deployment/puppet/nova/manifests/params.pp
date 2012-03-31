# these parameters need to be accessed from several locations and
# should be considered to be constant
class nova::params {

  case $::osfamily {
    'RedHat': {
      $common_package_name      = 'openstack-nova'
      $api_package_name         = undef
      $compute_package_name     = undef
      $network_package_name     = undef
      $objectstore_package_name = undef
      $scheduler_package_name   = undef
      $doc_package_name         = 'openstack-nova-doc'
      $api_service_name         = 'openstack-nova-api'
      $compute_service_name     = 'openstack-nova-compute'
      $network_service_name     = 'openstack-nova-network'
      $objectstore_service_name = 'openstack-nova-objectstore'
      $scheduler_service_name   = 'openstack-nova-scheduler'
      $libvirt_package_name     = 'libvirt'
      $libvirt_service_name     = 'libvirtd'
      $special_service_provider = 'init'
      # redhat specific config defaults
      $root_helper              = 'sudo nova-rootwrap'
    }
    'Debian': {
      $common_package_name      = 'nova-common'
      $api_package_name         = 'nova-api'
      $compute_package_name     = 'nova-compute'
      $network_package_name     = 'nova-network'
      $objectstore_package_name = 'nova-objectstore'
      $scheduler_package_name   = 'nova-scheduler'
      $doc_package_name         = 'nova-doc'
      $api_service_name         = 'nova-api'
      $compute_service_name     = 'nova-compute'
      $network_service_name     = 'nova-network'
      $objectstore_service_name = 'nova-objectstore'
      $scheduler_service_name   = 'nova-scheduler'
      $libvirt_package_name     = 'libvirt-bin'
      $libvirt_service_name     = 'libvirt-bin'
      # some of the services need to be started form the special upstart provider
      $special_service_provider = 'upstart'
      # debian specific nova config
      $root_helper              = 'sudo'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

}
