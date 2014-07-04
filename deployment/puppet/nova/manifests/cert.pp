# == Class: nova::cert
#
# Installs nova cert package and service
#
# === Parameters:
#
# [*enabled*]
#   (optional) Whether or not to enable the nova cert service
#   Defaults to false
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*ensure_package*]
#   (optional) The state to set for the nova-cert package
#   Defaults to 'present'
#
class nova::cert(
  $enabled        = false,
  $manage_service = true,
  $ensure_package = 'present'
) {

  include nova::params

  nova::generic_service { 'cert':
    enabled        => $enabled,
    manage_service => $manage_service,
    package_name   => $::nova::params::cert_package_name,
    service_name   => $::nova::params::cert_service_name,
    ensure_package => $ensure_package,
  }

}
