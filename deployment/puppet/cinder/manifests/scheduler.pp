#
class cinder::scheduler (
  $package_ensure = 'installed',
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
  case $::osfamily {
    "Debian":  {
      File[$::cinder::params::cinder_conf] -> Cinder_config<||>
      File[$::cinder::params::cinder_paste_api_ini] -> Cinder_api_paste_ini<||>
      Cinder_config <| |> -> Package['cinder-scheduler']
      Cinder_api_paste_ini<||> -> Package['cinder-scheduler']
    }
    "RedHat": {
  Package[$scheduler_package] -> Cinder_api_paste_ini<||>
  Package[$scheduler_package] -> Cinder_config<||>
    }
  }
  Cinder_config<||> ~> Service['cinder-scheduler']
  Cinder_config<||> ~> Exec['cinder-manage db_sync']
  Cinder_api_paste_ini<||> ~> Service['cinder-scheduler']
  Exec['cinder-manage db_sync'] -> Service['cinder-scheduler']



  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  service { 'cinder-scheduler':
    name      => $::cinder::params::scheduler_service,
    enable    => $enabled,
    ensure    => $ensure,
    hasstatus  => true,
    hasrestart => true,
    require   => Package[$scheduler_package],
    subscribe => File[$::cinder::params::cinder_conf],
  }
  Package<| title == $scheduler_package|> ~> Service<| title == 'cinder-scheduler'|>
  if !defined(Service['cinder-scheduler']) {
    notify{ "Module ${module_name} cannot notify service cinder-scheduler on package update": }
  }
}
