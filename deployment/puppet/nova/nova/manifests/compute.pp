class nova::compute( 
  $enabled = false,
  $nova_config = '/etc/nova/nova.conf' 
) {
  
  Nova_config<| |>~>Service['nova_compute']

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
