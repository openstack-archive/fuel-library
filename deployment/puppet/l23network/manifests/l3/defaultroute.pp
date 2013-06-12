# == Define: l23network::l3::defaultroute
#
# Do not use this directly,
# use l23network::l3::route instead
#
define l23network::l3::defaultroute (
    $gateway = $name,
    $metric  = undef,
){
  case $::osfamily {
    /(?i)debian/: {
        fail("Unsupported for ${::osfamily}/${::operatingsystem}!!! Specify gateway directly for network interface.")
    }
    /(?i)redhat/: {
        if ! defined(Cfg[$gateway]) {
          cfg { $gateway:
              file  => '/etc/sysconfig/network',
              key   => 'GATEWAY',
              value => $gateway,
          }
        }
    }
    default: {
        fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }

}
#
###