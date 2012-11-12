class quantum::client (
  $package_ensure = present
) {
  include 'quantum::params'
  package { 'python-quantumclient':
    name   => $::quantum::params::client_package_name,
    ensure => $package_ensure
  }
}
