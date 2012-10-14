#
# installs nova cert package and service
#
class nova::cert(
  $enabled        = false,
  $ensure_package = 'present'
) {

  include nova::params

  nova::generic_service { 'cert':
    enabled        => $enabled,
    package_name   => $::nova::params::cert_package_name,
    service_name   => $::nova::params::cert_service_name,
    ensure_package => $ensure_package,
  }

}
