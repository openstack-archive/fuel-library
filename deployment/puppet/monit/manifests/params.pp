#
class monit::params {
  case $::osfamily {
    'RedHat' : {
      $idfile     = '/var/.monit.id'
      $statefile  = '/var/.monit.state'
      $basedir    = '/var/monit'
      $included   = '/etc/monit.d'
      $config     = '/etc/monit.conf'
    }
    'Debian' : {
      $idfile     = '/var/lib/monit/id'
      $statefile  = '/var/lib/monit/state'
      $basedir    = '/var/lib/monit/events'
      $included   = '/etc/monit/conf.d'
      $config     = '/etc/monit/monitrc'
    }
    default  : {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }
}
