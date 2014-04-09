# == Class nova::client
#
# installs nova client
#
# === Parameters:
#
# [*ensure*]
#   (optional) The state for the nova client package
#   Defaults to 'present'
#
class nova::client(
  $ensure = 'present'
) {

  package { 'python-novaclient':
    ensure => $ensure,
  }

}
