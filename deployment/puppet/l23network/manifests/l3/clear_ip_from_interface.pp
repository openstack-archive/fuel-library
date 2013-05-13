# == Define: l23network::l3::clear_ip_from_interface
#
# Flush any IP addresses from interface
#
# === Parameters
#
# [*name*]
#   Interface to be flushed.
#
define l23network::l3::clear_ip_from_interface {
    exec { "ip addr flush ${name}":
      path => '/usr/bin:/usr/sbin:/bin:/sbin',
    }
}
