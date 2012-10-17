class glance::client (
  $ensure = present
) {
  package { "python-quantumclient":
    name   => $::glance::params::client_package_name,
    ensure => $ensure
  }
}
