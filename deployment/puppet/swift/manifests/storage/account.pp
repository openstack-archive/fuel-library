class swift::storage::account(
  $package_ensure = 'present'
) {
  swift::storage::generic { 'account':
    package_ensure => $package_ensure,
  }

  @@ring_account_device { "${swift_local_net_ip}:${port}":
    zone => $swift_zone,
    mountpoints => $swift_mountpoints,
  }
}
