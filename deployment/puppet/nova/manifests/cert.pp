class nova::cert(
  $enabled=false
) inherits nova{

  nova::generic_service { 'cert':
    enabled      => $enabled,
    package_name => $::nova::params::cert_package_name,
    service_name => $::nova::params::cert_service_name,
  }

}
