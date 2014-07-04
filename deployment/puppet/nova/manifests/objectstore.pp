# == Class: nova::objectstore
#
# Manages the nova-objectstore service
#
# === Parameters:
#
# [*enabled*]
#   (optional) Whether to enable the service
#   Defaults to false
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*ensure_package*]
#   (optional) The package state to set
#   Defaults to 'present'
#
# [*bind_address*]
#   (optional) The address to bind to
#   Defaults to '0.0.0.0'
#
class nova::objectstore(
  $enabled        = false,
  $manage_service = true,
  $ensure_package = 'present',
  $bind_address   = '0.0.0.0'
) {

  include nova::params

  nova::generic_service { 'objectstore':
    enabled        => $enabled,
    manage_service => $manage_service,
    package_name   => $::nova::params::objectstore_package_name,
    service_name   => $::nova::params::objectstore_service_name,
    ensure_package => $ensure_package,
    require        => User['nova'],
  }

  nova_config {
    'DEFAULT/s3_listen':  value => $bind_address;
  }
}
