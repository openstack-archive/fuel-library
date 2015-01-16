# == Define Resource Type: haproxy::userlist
#
# This type will set up a userlist configuration block inside the haproxy.cfg
#  file on an haproxy load balancer.
#
# See http://cbonte.github.io/haproxy-dconv/configuration-1.4.html#3.4 for more info
#
# === Requirement/Dependencies:
#
# Currently requires the puppetlabs/concat module on the Puppet Forge
#
# === Parameters
#
# [*name*]
#   The namevar of the define resource type is the userlist name.
#    This name goes right after the 'userlist' statement in haproxy.cfg
#
# [*users*]
#   An array of users in the userlist.
#   See http://cbonte.github.io/haproxy-dconv/configuration-1.4.html#3.4-user
#
# [*groups*]
#   An array of groups in the userlist.
#   See http://cbonte.github.io/haproxy-dconv/configuration-1.4.html#3.4-group
#
# === Authors
#
# Jeremy Kitchen <jeremy@nationbuilder.com>
#
define haproxy::userlist (
  $users = undef,
  $groups = undef,
) {

  # Template usse $name, $users, $groups
  concat::fragment { "${name}_userlist_block":
    order   => "12-${name}-00",
    target  => $::haproxy::config_file,
    content => template('haproxy/haproxy_userlist_block.erb'),
  }
}
