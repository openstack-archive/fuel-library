class swift::storage::account(
  $package_ensure = 'present'
) {
  swift::storage::generic { 'account':
    package_ensure => $package_ensure,
  }
}
