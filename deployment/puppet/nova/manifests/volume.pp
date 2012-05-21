class nova::volume(
  $enabled = false
) {

  include 'nova::params'

  nova::generic_service { 'volume':
    enabled      => $enabled,
    package_name => $::nova::params::volume_package_name,
    service_name => $::nova::params::volume_service_name,
  }

}
