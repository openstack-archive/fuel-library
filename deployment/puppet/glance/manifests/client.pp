#
# Installs the glance python library.
#
class glance::client (
  $ensure = $::openstack_version['glance']
) {

  package { 'python-glance':
    name   => $::glance::params::client_package_name,
    ensure => $ensure,
  }

}
