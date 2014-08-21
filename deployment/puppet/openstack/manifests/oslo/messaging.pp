# Installs Oslo messaging package which is common Openstack library.
# Openstack services should be notified.
#
class openstack::oslo::messaging ()
{
  case $::osfamily {
    'RedHat': {
      $oslo_messaging_package_name = 'python-oslo-messaging'
    }
    'Debian': {
      $oslo_messaging_package_name = 'python-oslo.messaging'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem},\
 module ${module_name} only support osfamily RedHat and Debian")
    }
  }

  package { $oslo_messaging_package_name: ensure => installed }
}



