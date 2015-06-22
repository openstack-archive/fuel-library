# == Class: nova::conductor
#
# Manages nova conductor package and service
#
# === Parameters:
#
# [*enabled*]
#   (optional) Whether to enable the nova-conductor service
#   Defaults to false
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*ensure_package*]
#   (optional) The state of the nova conductor package
#   Defaults to 'present'
#
# [*workers*]
#   (optional) Number of workers for OpenStack Conductor service
#   Defaults to undef (i.e. parameter will not be present)
#
class nova::conductor(
  $enabled        = false,
  $manage_service = true,
  $ensure_package = 'present',
  $workers        = undef,
) {

  include ::nova::db
  include ::nova::params

  nova::generic_service { 'conductor':
    enabled        => $enabled,
    manage_service => $manage_service,
    package_name   => $::nova::params::conductor_package_name,
    service_name   => $::nova::params::conductor_service_name,
    ensure_package => $ensure_package,
  }

  if $workers {
    nova_config {
      'conductor/workers': value => $workers;
    }
  }
}
