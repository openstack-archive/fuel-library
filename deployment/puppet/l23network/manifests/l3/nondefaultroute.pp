# == Define: l23network::l3::nondefaultroute
#
# Do not use this directly,
# use
# l23network::l3::route
#
define l23network::l3::nondefaultroute (
    $route       = $name,
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

