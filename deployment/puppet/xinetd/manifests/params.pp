class xinetd::params {

  case $::osfamily {
    'Debian':  {
      $confdir            = '/etc/xinetd.d'
      $conffile           = '/etc/xinetd.conf'
      $package_name       = 'xinetd'
      $service_hasrestart = true
      $service_hasstatus  = false
      $service_name       = 'xinetd'
      $service_restart    = "/usr/sbin/service ${service_name} reload"
    }
    'FreeBSD': {
      $confdir            = '/usr/local/etc/xinetd.d'
      $conffile           = '/usr/local/etc/xinetd.conf'
      $package_name       = 'security/xinetd'
      $service_hasrestart = false
      $service_hasstatus  = true
      $service_name       = 'xinetd'
    }
    'Suse':  {
      $confdir            = '/etc/xinetd.d'
      $conffile           = '/etc/xinetd.conf'
      $package_name       = 'xinetd'
      $service_hasrestart = true
      $service_hasstatus  = false
      $service_name       = 'xinetd'
      $service_restart    = "/sbin/service ${service_name} reload"
    }
    'RedHat':  {
      $confdir            = '/etc/xinetd.d'
      $conffile           = '/etc/xinetd.conf'
      $package_name       = 'xinetd'
      $service_hasrestart = true
      $service_hasstatus  = true
      $service_name       = 'xinetd'
      $service_restart    = "/sbin/service ${service_name} reload"
    }
    'Linux': {
      case $::operatingsystem {
        'Amazon': {
          $confdir      = '/etc/xinetd.d'
          $conffile     = '/etc/xinetd.conf'
          $package_name = 'xinetd'
          $service_name = 'xinetd'
        }
        default: {
          fail("xinetd: module does not support Linux operatingsystem ${::operatingsystem}")
        }
      }
    }
    default:   {
      fail("xinetd: module does not support osfamily ${::osfamily}")
    }
  }

}

