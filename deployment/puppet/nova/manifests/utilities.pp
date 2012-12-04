# unzip swig screen parted curl euca2ools - extra packages
class nova::utilities {
  include nova::params
  package { ['unzip', 'screen', 'curl', 'euca2ools']:
    ensure => present
  }
  if !(defined(Package['parted'])) {
    package {"parted": ensure => 'present' }
  }
  case $::osfamily {
 'Debian': {
      file { "/tmp/guestfs.seed":   
        ensure => present,
        source => 'puppet:///modules/nova/guestfs.seed'
      }->
      package {"$::nova::params::guestmount_package_name": ensure => present, responsefile=>"/tmp/guestfs.seed"}
 }
'RedHat': {
  package {"$::nova::params::guestmount_package_name": ensure => present}
}
}
}


