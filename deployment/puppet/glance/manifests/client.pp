#
# Installs the glance python library.
#
class glance::client (
  $ensure = 'present',
) {

  package { 'python-glance':
    ensure => $ensure,
  }

}