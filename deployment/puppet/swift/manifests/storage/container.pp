class swift::storage::container(
  $package_ensure = 'present'
) {
  swift::storage::generic { 'container':
    package_ensure => $package_ensure
  }

  @@ring_container_device { "${swift_local_net_ip}:${port}":
    zone => $swift_zone,
    mountpoints => $swift_mountpoints,
  }

}
