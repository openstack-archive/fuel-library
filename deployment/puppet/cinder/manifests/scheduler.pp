# == Class: cinder::scheduler
#
#  Scheduler class for cinder.
#
# === Parameters
#
# [*scheduler_driver*]
#   (Optional) Default scheduler driver to use
#   Defaults to 'false'.
#
# [*package_ensure*]
#   (Optioanl) The state of the package.
#   Defaults to 'present'.
#
# [*enabled*]
#   (Optional) The state of the service
#   Defaults to 'true'.
#
# [*manage_service*]
#   (Optional) Whether to start/stop the service
#   Defaults to 'true'.
#
#
class cinder::scheduler (
  $scheduler_driver = false,
  $package_ensure   = 'present',
  $enabled          = true,
  $manage_service   = true
) {

  include ::cinder::params

  Cinder_config<||> ~> Service['cinder-scheduler']
  Cinder_api_paste_ini<||> ~> Service['cinder-scheduler']
  Exec<| title == 'cinder-manage db_sync' |> ~> Service['cinder-scheduler']

  if $scheduler_driver {
    cinder_config {
      'DEFAULT/scheduler_driver': value => $scheduler_driver;
    }
  } else {
    cinder_config {
      'DEFAULT/scheduler_driver': ensure => absent;
    }
  }

  if $::cinder::params::scheduler_package {
    Package['cinder-scheduler'] -> Cinder_config<||>
    Package['cinder-scheduler'] -> Cinder_api_paste_ini<||>
    Package['cinder-scheduler'] -> Service['cinder-scheduler']
    package { 'cinder-scheduler':
      ensure => $package_ensure,
      name   => $::cinder::params::scheduler_package,
      tag    => 'openstack',
    }
  }

  if $manage_service {
    if $enabled {
      $ensure = 'running'
    } else {
      $ensure = 'stopped'
    }
  }

  service { 'cinder-scheduler':
    ensure    => $ensure,
    name      => $::cinder::params::scheduler_service,
    enable    => $enabled,
    hasstatus => true,
    require   => Package['cinder'],
  }
}
