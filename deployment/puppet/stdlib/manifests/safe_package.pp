define stdlib::safe_package (
  $ensure = present,
) {
  if !defined(Package[$title]) {
    package { $title:
      name   => $name,
      ensure => $ensure
    }
  }
}
