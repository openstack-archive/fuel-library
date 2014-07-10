# == Class: neutron::client
#
# Manages the neutron client package on systems
#
# === Parameters:
#
# [*package_ensure*]
#   (optional) The state of the package
#   Defaults to present
#
class neutron::client (
  $package_ensure = present
) {

  include neutron::params

  package { 'python-neutronclient':
    ensure => $package_ensure,
    name   => $::neutron::params::client_package,
  }

}
