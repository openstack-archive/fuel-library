#
class cinder::scheduler (
  $package_ensure = 'latest',
  $enabled        = true
) {

  include cinder::params

  if ($::cinder::params::scheduler_package) { 
    $scheduler_package = $::cinder::params::scheduler_package
    package { 'cinder-scheduler':
      name   => $scheduler_package,
      ensure => $package_ensure,
    }
  } else {
    $scheduler_package = $::cinder::params::package_name
  }

  Package[$scheduler_package] -> Cinder_config<||>
  Package[$scheduler_package] -> Cinder_api_paste_ini<||>
  Cinder_api_paste_ini<||> ~> Service['cinder-scheduler']
  Exec<| title == 'cinder-manage db_sync' |> ~> Service['cinder-scheduler']

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  service { 'cinder-scheduler':
    name      => $::cinder::params::scheduler_service,
    enable    => $enabled,
    ensure    => $ensure,
    require   => Package[$scheduler_package],
    subscribe => File[$::cinder::params::cinder_conf],
  }
}
