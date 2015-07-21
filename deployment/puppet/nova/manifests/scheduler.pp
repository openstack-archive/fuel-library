# == Class: nova::scheduler
#
# Install and manage nova scheduler
#
# === Parameters:
#
# [*enabled*]
#   (optional) Whether to run the scheduler service
#   Defaults to false
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*ensure_package*]
#   (optional) The state of the scheduler package
#   Defaults to 'present'
#
# [*scheduler_driver*]
#   (optional) Default driver to use for the scheduler
#   Defaults to 'nova.scheduler.filter_scheduler.FilterScheduler'
#
class nova::scheduler(
  $enabled          = false,
  $manage_service   = true,
  $ensure_package   = 'present',
  $scheduler_driver = 'nova.scheduler.filter_scheduler.FilterScheduler',
) {

  include ::nova::db
  include ::nova::params

  nova::generic_service { 'scheduler':
    enabled        => $enabled,
    manage_service => $manage_service,
    package_name   => $::nova::params::scheduler_package_name,
    service_name   => $::nova::params::scheduler_service_name,
    ensure_package => $ensure_package,
  }

  nova_config {
    'DEFAULT/scheduler_driver': value => $scheduler_driver;
  }

  Nova_config['DEFAULT/scheduler_driver'] ~> Service <| title == 'nova-scheduler' |>

}
