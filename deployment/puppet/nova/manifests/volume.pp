class nova::volume(
  $enabled        = false,
  $ensure_package = 'present'
) {

  include 'nova::params'

  exec { 'volumes':
    command => 'dd if=/dev/zero of=/tmp/nova-volumes.img bs=1M seek=20k count=0 && /sbin/vgcreate nova-volumes `/sbin/losetup --show -f /tmp/nova-volumes.img`',
    onlyif => 'test ! -e /tmp/nova-volumes.img',
    path => ["/usr/bin", "/bin", "/usr/local/bin"],
    before => Service['nova-volume'],
  }

  nova::generic_service { 'volume':
    enabled        => $enabled,
    package_name   => $::nova::params::volume_package_name,
    service_name   => $::nova::params::volume_service_name,
    ensure_package => $ensure_package,
  }

  package { 'tgt':
    name   => $::nova::params::tgt_package_name,
    ensure => present,
  }
  # TODO is this fedora specific?
  service {'tgtd':
    name     => $::nova::params::tgt_service_name,
    provider => $::nova::params::special_service_provider,
    ensure   => $service_ensure,
    enable   => $enabled,
    require  => [Nova::Generic_service['volume'], Package['tgt']],
  }
}
