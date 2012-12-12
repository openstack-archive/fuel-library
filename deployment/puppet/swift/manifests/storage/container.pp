class swift::storage::container(
  $swift_zone,
  $port,
  $storage_local_net_ip,
  $package_ensure = 'present'
) {
  swift::storage::generic { 'container':
    package_ensure => $package_ensure
  }

  @@ring_container_device { "${storage_local_net_ip}:${port}":
    zone => $swift_zone,
    mountpoints => $::swift_mountpoints,
  }

}
