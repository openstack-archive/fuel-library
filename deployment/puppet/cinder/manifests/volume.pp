# $volume_name_template = volume-%s
class cinder::volume (
  $package_ensure = 'latest',
  $enabled        = true
) {

  include cinder::params

  if ($::cinder::params::volume_package) { 
    $volume_package = $::cinder::params::volume_package
    Package['cinder'] -> Package[$volume_package]

    package { 'cinder-volume':
      name   => $volume_package,
      ensure => $package_ensure,
    }
  } else {
    $volume_package = $::cinder::params::package_name
  }

  Package[$volume_package] -> Cinder_config<||>
  Package[$volume_package] -> Cinder_api_paste_ini<||>
  Cinder_config<||> ~> Service['cinder-volume']
  Cinder_api_paste_ini<||> ~> Service['cinder-volume']

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  service { 'cinder-volume':
    name      => $::cinder::params::volume_service,
    enable    => $enabled,
    ensure    => $ensure,
    require   => Package[$volume_package],
    subscribe => File[$::cinder::params::cinder_conf],
  }

}
