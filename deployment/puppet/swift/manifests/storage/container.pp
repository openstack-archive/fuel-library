class swift::storage::container(
  $package_ensure = 'present'
) {
  swift::storage::generic { 'container':
    package_ensure => $package_ensure
  }
}
