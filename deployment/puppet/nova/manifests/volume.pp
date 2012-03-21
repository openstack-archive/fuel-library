class nova::volume( $enabled=false ) {

  Exec['post-nova_config'] ~> Service['nova-volume']
  Exec['nova-db-sync'] ~> Service['nova-volume']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  exec {volumes:
    command => 'dd if=/dev/zero of=/tmp/nova-volumes.img bs=1M seek=20k count=0 && /sbin/vgcreate nova-volumes `/sbin/losetup --show -f /tmp/nova-volumes.img`',
    onlyif => 'test ! -e /tmp/nova-volumes.img',
    path => ["/usr/bin", "/bin", "/usr/local/bin"],
    before => Service['nova-volume'],
  }

  service { "nova-volume":
    name => 'openstack-nova-volume',
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package["openstack-nova"],
    #subscribe => File["/etc/nova/nova.conf"]
  }

  service {'tgtd':
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package["openstack-nova"],
  }
}
