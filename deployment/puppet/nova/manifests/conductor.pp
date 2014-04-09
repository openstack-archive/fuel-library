#
# installs nova conductor package and service
#
class nova::conductor(
  $enabled        = false,
  $ensure_package = 'present'
) {

  include nova::params

  nova::generic_service { 'conductor':
    enabled        => $enabled,
    package_name   => $::nova::params::conductor_package_name,
    service_name   => $::nova::params::conductor_service_name,
    ensure_package => $ensure_package,
  }

}
