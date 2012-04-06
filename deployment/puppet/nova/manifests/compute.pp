#schedulee this class should probably never be declared except
# from the virtualization implementation of the compute node
class nova::compute(
  $enabled = false,
) inherits nova {

  nova::generic_service { 'compute':
    enabled      => $enabled,
    package_name => $::nova::params::compute_package_name,
    service_name => $::nova::params::compute_service_name,
    before       => Exec['networking-refresh']
  }

}
