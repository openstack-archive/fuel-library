class nova::network( $enabled=false ) {

  Exec['post-nova_config'] ~> Service['nova-network']
  Exec['nova-db-sync'] ~> Service['nova-network']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  package { "nova-network":
    ensure  => present,
    require => Package["python-greenlet"]
  }

  service { "nova-network":
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package["nova-network"],
    before  => Exec['networking-refresh'],
    #subscribe => File["/etc/nova/nova.conf"]
  }
}
