# unzip swig screen parted curl euca2ools - extra packages
class nova::utilities {
  include nova::params
  package { ['unzip', 'screen', 'curl', 'euca2ools', $::nova::params::guestmount_package_name]:
    ensure => present
  }
  if !(defined(Package['parted'])) {
    package {"parted": ensure => 'present' }
  }

}
