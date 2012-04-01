class nova::volume(
  $enabled=false
) inherits nova {

  exec { 'volumes':
    command => 'dd if=/dev/zero of=/tmp/nova-volumes.img bs=1M seek=20k count=0 && /sbin/vgcreate nova-volumes `/sbin/losetup --show -f /tmp/nova-volumes.img`',
    onlyif => 'test ! -e /tmp/nova-volumes.img',
    path => ["/usr/bin", "/bin", "/usr/local/bin"],
    before => Service['nova-volume'],
  }

  ova::generic_service { 'volume':
    enabled      => $enabled,
    package_name => $::nova::params::volume_package_name,
    service_name => $::nova::params::volume_service_name,
  }

  # TODO is this fedora specific?
  service {'tgtd':
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package["openstack-nova"],
  }
}
