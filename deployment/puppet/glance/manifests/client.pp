#
# Installs the glance python library.
#
# == parameters
#  [*ensure*]
#    (Optional) Ensure state for pachage.
#    Defaults to 'present'
#
class glance::client (
  $ensure = 'present'
) {

  include ::glance::params

  package { 'python-glanceclient':
    ensure => $ensure,
    name   => $::glance::params::client_package_name,
    tag    => ['openstack'],
  }

}
