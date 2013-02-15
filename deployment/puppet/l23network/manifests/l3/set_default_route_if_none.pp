# == Define: l23network::l3::set_default_route_if_none
#
# add default route to the routing table if it not exists.
#
# === Parameters
#
# [*route*]
#   Route that will be added.
#
# [*timeout*]
#   Timeout before checking exists or not default route in routing table.
#
define l23network::l3::set_default_route_if_none (
    $route = $::l3_default_route,
    $timeout = 10,
){
  if $route {
    exec { "ip route add default via ${route}":
      path   => '/usr/bin:/usr/sbin:/bin:/sbin',
      unless => "sleep ${timeout} ; ip route list | grep default",
    }
  }
}
