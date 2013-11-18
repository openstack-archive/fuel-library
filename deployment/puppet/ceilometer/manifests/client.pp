#
# Installs the ceilometer python library.
#
# == parameters
#  [*ensure*]
#    ensure state for pachage.
#
class ceilometer::client (
  $ensure = 'present'
) {

  include ceilometer::params

  package { 'python-ceilometerclient':
    ensure => $ensure,
    name   => $::ceilometer::params::client_package_name,
  }

}

