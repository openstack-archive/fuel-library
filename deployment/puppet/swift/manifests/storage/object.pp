class swift::storage::object(
  $package_ensure = 'present'
) {
  swift::storage::generic { 'object':
    package_ensure => $package_ensure
  }

  @@ring_object_device { "${swift_local_net_ip}:${swift::storage::all::object_port}":
    zone => $swift_zone,
    mountpoints => $::swift_mountpoints,
  }
}
