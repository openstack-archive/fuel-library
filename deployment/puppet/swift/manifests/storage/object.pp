class swift::storage::object(
  $package_ensure = 'present'
) {
  swift::storage::generic { 'object':
    package_ensure => $package_ensure
  }

  @@ring_object_device { "${swift::storage::all::storage_local_net_ip}:${swift::storage::all::object_port}":
    zone => $swift::storage::all::swift_zone,
    mountpoints => $::swift_mountpoints,
  }
}
