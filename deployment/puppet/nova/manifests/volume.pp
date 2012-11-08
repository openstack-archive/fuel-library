#
# configures nova::volume.
# This has been deprecated in favor of cinder
#
class nova::volume(
  $enabled        = false,
  $ensure_package = 'present'
) {

  include 'nova::params'

  nova::generic_service { 'volume':
    enabled        => $enabled,
    ensure_package => $ensure_package,
    package_name   => $::nova::params::volume_package_name,
    service_name   => $::nova::params::volume_service_name,
  }

}
