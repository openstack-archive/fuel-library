# == Define: l23network::l3::defaultroute
#
# Do not use this directly,
# use l23network::l3::route instead
#
class l23network::l3::defaultroute (
    $gateway = $name,
    $metric      = undef,
){
  case $::osfamily {
    /(?i)debian/: {
        fail("Unsupported for ${::osfamily}/${::operatingsystem}!!! Specify gateway directly for network interface.")
    }
    /(?i)redhat/: {
        cfg { 'GATEWAY':
            file => '/etc/sysconfig/network',
            value => $gateway,
        }
    }
    default: {
        fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }

}
#
###