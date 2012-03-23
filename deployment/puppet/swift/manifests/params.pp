class swift::params {
  case $osfamily {
    'Debian': {
      $package_name           = 'swift'
      $proxy_package_name     = 'swift-proxy'
      $proxy_service_name     = 'swift-proxy'
      $object_package_name    = 'swift-object'
      $object_service_name    = 'swift-object'
      $container_package_name = 'swift-container'
      $container_service_name = 'swift-container'
      $account_package_name   = 'swift-account'
      $account_service_name   = 'swift-account'
      $service_provider       = 'upstart'
    }
    'RedHat': {
      $package_name           = 'openstack-swift'
      $proxy_package_name     = 'openstack-swift-proxy'
      $proxy_service_name     = 'openstack-swift-proxy'
      $object_package_name    = 'openstack-swift-object'
      $object_service_name    = 'openstack-swift-object'
      $container_package_name = 'openstack-swift-container'
      $container_service_name = 'openstack-swift-container'
      $account_package_name   = 'openstack-swift-account'
      $account_service_name   = 'openstack-swift-account'
      $service_provider       = undef
    }
    default: {
        fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }
}
