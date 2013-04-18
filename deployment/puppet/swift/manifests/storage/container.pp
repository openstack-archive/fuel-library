class swift::storage::container(
  $package_ensure = 'present',
  $swift_mountpoints = $::swift_mountpoints,
) {
  swift::storage::generic { 'container':
    package_ensure => $package_ensure
  }

  if $swift::storage::all::export_devices {
    @@ring_container_device { "${swift::storage::all::storage_local_net_ip}:${swift::storage::all::container_port}":
      zone => $swift::storage::all::swift_zone,
      mountpoints => $swift_mountpoints,
    }
  }

}
