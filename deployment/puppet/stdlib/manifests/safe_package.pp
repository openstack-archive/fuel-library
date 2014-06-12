define stdlib::safe_package (
  $ensure = present,
) {
  if ! defined(Package[$name]) {
    package { $name:
      name   => $name,
      ensure => $ensure
    }
  }
}
