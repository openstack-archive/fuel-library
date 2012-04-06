class nova::scheduler(
  $enabled = false
) inherits nova {

  nova::generic_service { 'scheduler':
    enabled      => $enabled,
    package_name => $::nova::params::scheduler_package_name,
    service_name => $::nova::params::scheduler_service_name,
  }

}
