# this class should probably never be declared except
# from the virtualization implementation of the compute node
class nova::compute( 
  $enabled = false
) {

  Nova_config<| |>~>Service['nova-compute']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  package { "nova-compute":
    ensure => present,
    require => Class['nova']
  }

  service { "nova-compute":
    ensure => $service_ensure,
    enable => $enabled,
    require => Package["nova-compute"],
  }
}
