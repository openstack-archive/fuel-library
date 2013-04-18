class swift::storage::account(
  $package_ensure = 'present',
  $swift_mountpoints = $::swift_mountpoints,
) {
  swift::storage::generic { 'account':
    package_ensure => $package_ensure,
  }

  if $swift::storage::all::export_devices {
    @@ring_account_device { "${swift::storage::all::storage_local_net_ip}:${swift::storage::all::account_port}":
      zone => $swift::storage::all::swift_zone,
      mountpoints => $swift_mountpoints,
    }
  }
}
