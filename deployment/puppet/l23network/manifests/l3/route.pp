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
    $gateway,
    $route       = $name,
    $metric      = undef,
){
  case $route {
    /(?i)default/: { # default routing
      l23network::l3::defaultroute {'default':
        gateway => $gateway,
        metric  => $metric,
      }
    }
    default: {       # non-default routing
      l23network::l3::nondefaultroute {$route:
        gateway => $gateway,
        metric  => $metric,
      }
    }
  }
}
