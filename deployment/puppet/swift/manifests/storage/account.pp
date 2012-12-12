class swift::storage::account(
  $swift_zone,
  $port,
  $storage_local_net_ip,
  $package_ensure = 'present',
) {
  swift::storage::generic { 'account':
    package_ensure => $package_ensure,
  }

  @@ring_account_device { "${storage_local_net_ip}:${port}":
    zone => $swift_zone,
    mountpoints => $::swift_mountpoints,
  }
}
