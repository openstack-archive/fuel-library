class quantum::client (
  $package_ensure = present
) {
  include 'quantum::params'
  stdlib::safe_package { 'python-quantumclient':
    name   => $::quantum::params::client_package_name,
    ensure => $package_ensure
  }
}
