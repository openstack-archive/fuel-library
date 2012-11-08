#
# installs nova client
#
class nova::client(
  $ensure = 'present'
) {

  package { 'python-novaclient':
    ensure => $ensure,
  }

}
