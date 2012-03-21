class nova::network( $enabled=false ) {

  Exec['post-nova_config'] ~> Service['nova-network']
  Exec['nova-db-sync'] ~> Service['nova-network']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { "nova-network":
    name => $::nova::params::network_service_name,
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package[$::nova::params::package_names],
    before  => Exec['networking-refresh'],
    #subscribe => File["/etc/nova/nova.conf"]
  }
}
