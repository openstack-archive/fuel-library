class nailgun::nginx-service (
  $service_enabled = true,
) {

  if ( $service_enabled == false ){
    $ensure = false
  } else {
    $ensure = 'running'
  }
  service { 'nginx':
    enable => $service_enabled,
    ensure => $ensure,
    require => Package["nginx"],
  }
}
