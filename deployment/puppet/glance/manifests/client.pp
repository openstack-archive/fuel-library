#
# Installs the glance python library.
#
# == parameters
#  * ensure - ensure state for pachage.
#
class glance::client (
  $ensure = 'present'
) {

  include glance::params

  package { 'python-glanceclient':
    ensure => $ensure,
    name   => $::glance::params::client_package_name,
  }

}
