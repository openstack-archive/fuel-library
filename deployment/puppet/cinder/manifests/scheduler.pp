#
class cinder::scheduler (
  $scheduler_driver = false,
  $package_ensure   = 'present',
  $enabled          = true,
  $manage_service   = true
) {

  include cinder::params

  Cinder_config<||> ~> Service['cinder-scheduler']
  Cinder_api_paste_ini<||> ~> Service['cinder-scheduler']
  Exec<| title == 'cinder-manage db_sync' |> ~> Service['cinder-scheduler']

  if $scheduler_driver {
    cinder_config {
      'DEFAULT/scheduler_driver': value => $scheduler_driver;
    }
  }

  if $::cinder::params::scheduler_package {
    Package['cinder-scheduler'] -> Cinder_config<||>
    Package['cinder-scheduler'] -> Cinder_api_paste_ini<||>
    Package['cinder-scheduler'] -> Service['cinder-scheduler']
    package { 'cinder-scheduler':
      ensure => $package_ensure,
      name   => $::cinder::params::scheduler_package,
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
