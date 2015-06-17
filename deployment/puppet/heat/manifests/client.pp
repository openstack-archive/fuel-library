# == Class: heat::client
#
# Installs the heat python library.
#
# === Parameters
#
# [*ensure*]
#   (Optional) Ensure state for package.
#
class heat::client (
  $ensure = 'present'
) {

  include ::heat::params

  package { 'python-heatclient':
    ensure => $ensure,
    name   => $::heat::params::client_package_name,
    tag    => 'openstack',
  }

}
