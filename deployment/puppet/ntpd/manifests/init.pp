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

  exec{ 'ntp_init_force':
    command => "service ${service_name} stop ; awk '\$1==\"peer\"||\$1==\"server\"{ res=system(\"ntpdate \" \$2); if(res==0) exit 0; }' /etc/ntp.conf",
    path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    require => Package[$package_name],
  }

  service { $service_name:
    enable  => true,
    ensure  => running,
    require => Exec['ntp_init_force'],
  }

}
