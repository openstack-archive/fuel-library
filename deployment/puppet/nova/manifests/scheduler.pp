class nova::scheduler( $enabled ) {

  include nova::params

  Exec['post-nova_config'] ~> Service['nova-scheduler']
  Exec['nova-db-sync'] -> Service['nova-scheduler']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { "nova-scheduler":
    name => $::nova::params::scheduler_service_name,
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package[$::nova::params::package_names],
    #subscribe => File["/etc/nova/nova.conf"]
  }
}
