#
# install nova scheduler
#
class nova::scheduler(
  $enabled        = false,
  $ensure_package = 'present'
) {

  include nova::params

  nova::generic_service { 'scheduler':
    enabled        => $enabled,
    package_name   => $::nova::params::scheduler_package_name,
    service_name   => $::nova::params::scheduler_service_name,
    ensure_package => $ensure_package,
  }

}
