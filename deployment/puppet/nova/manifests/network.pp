class nova::network(
  $enabled=false
) {

  include nova::params

  nova::generic_service { 'network':
    enabled      => $enabled,
    package_name => $::nova::params::network_package_name,
    service_name => $::nova::params::network_service_name,
    before       => Exec['networking-refresh']
  }

}
