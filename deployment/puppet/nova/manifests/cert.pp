class nova::cert( $enabled=false ) {

  Exec['post-nova_config'] ~> Service['nova-cert']
  Exec['nova-db-sync'] ~> Service['nova-cert']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { "nova-cert":
    name => 'openstack-nova-cert',
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package["openstack-nova"],
    #subscribe => File["/etc/nova/nova.conf"]
  }
}
