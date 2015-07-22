# == Class: sahara::client
#
# Installs the sahara python library.
#
# === Parameters
#
# [*package_ensure*]
#   (Optional) Ensure state for package.
#   Default: present.
#
class sahara::client (
  $package_ensure = 'present'
) {

  include ::sahara::params

  package { 'python-saharaclient':
    ensure => $package_ensure,
    name   => $::sahara::params::client_package_name,
    tag    => 'openstack',
  }
}
