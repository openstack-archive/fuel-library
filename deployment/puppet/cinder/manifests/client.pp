# == Class: cinder::client
#
# Installs Cinder python client.
#
# === Parameters
#
# [*ensure*]
#   Ensure state for package. Defaults to 'present'.
#
class cinder::client(
  $package_ensure = 'present'
) {

  include cinder::params

  package { 'python-cinderclient':
    ensure => $package_ensure,
    name   => $::cinder::params::client_package,
  }
}
