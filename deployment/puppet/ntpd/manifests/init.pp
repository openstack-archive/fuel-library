#
# This module manages ntpd-service
#

class ntpd {

  case $::osfamily {
    'RedHat': {
      $package_name = 'ntp'
      $service_name = 'ntpd'
    }
    'Debian': {
      $package_name = 'openntpd'
      $service_name = 'openntpd'
    }
  }
  
  package { $package_name: ensure => present }

  service { $service_name:
    enable  => true,
    ensure  => running,
    require => Package[$package_name],
  }

}
