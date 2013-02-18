# == Define: l23network::l3::defaultroute
#
# Do not use this directly,
# use l23network::l3::route instead
#
define l23network::l3::defaultroute (
    $gateway,
    $metric      = undef,
){
  case $::osfamily {
    /(?i)debian/: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
    /(?i)redhat/: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }

}
