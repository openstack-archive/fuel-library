# == Define: l23network::l3::route
#
# Specify custom route.
#
# === Parameters
#
# [*route*]
#   Specify route. Required. Must be in CIDR format or 'default' string.
#   '192.168.0.0/16' for example.
#
# [*gateway*]
#   Specify gateway. Required.
#
# [*metric*]
#   Specify metroc for this route. Undefined by default.
#
define l23network::l3::route (
    $route       = $name,
    $gateway,
    $metric      = undef,
){
  case $route {
    /(?i)default/: { # default routing
      fail("default routing configuration not implemented. Use 'gateway' option while use l23network::l3::ifconfig.")
    }
    default: {       # non-default routing
      l23network::l3::nondefaultroute {"${route}":
        gateway => $gateway,
        metric  => $metric,
      }
    }
  }

}
