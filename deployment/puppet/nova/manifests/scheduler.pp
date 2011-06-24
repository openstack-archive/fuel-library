class nova::scheduler( $enabled ) {

  Exec['post-nova_config'] ~> Service['nova-scheduler']
  Exec['nova-db-sync'] -> Service['nova-scheduler']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  package { "nova-scheduler":
    ensure  => present,
    require => Package["python-greenlet"]
  }

  service { "nova-scheduler":
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package["nova-scheduler"],
    #subscribe => File["/etc/nova/nova.conf"]
  }
}
