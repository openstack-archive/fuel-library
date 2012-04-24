class nova::objectstore(
  $enabled=false
) {

  include nova::params

  nova::generic_service { 'objectstore':
    enabled      => $enabled,
    package_name => $::nova::params::objectstore_package_name,
    service_name => $::nova::params::objectstore_service_name,
  }

}
