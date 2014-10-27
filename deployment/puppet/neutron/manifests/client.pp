class neutron::client (
  $package_ensure = present
) {
  include 'neutron::params'
  package { 'python-neutronclient':
    name   => $::neutron::params::client_package_name,
    ensure => $package_ensure
  }
}

# vim: set ts=2 sw=2 et :