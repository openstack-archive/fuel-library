# == Define Resource Type: haproxy::backend
#
# This type will setup a backend service configuration block inside the
#  haproxy.cfg file on an haproxy load balancer.  Each backend service needs one
#  or more backend member servers (that can be declared with the
#  haproxy::balancermember defined resource type).  Using storeconfigs, you can
#  export the haproxy::balancermember resources on all load balancer member
#  servers and then collect them on a single haproxy load balancer server.
#
# === Requirement/Dependencies:
#
# Currently requires the puppetlabs/concat module on the Puppet Forge and
#  uses storeconfigs on the Puppet Master to export/collect resources
#  from all backend members.
#
# === Parameters
#
# [*name*]
#   The namevar of the defined resource type is the backend service's name.
#    This name goes right after the 'backend' statement in haproxy.cfg
#
# [*options*]
#   A hash of options that are inserted into the backend configuration block.
#
# [*collect_exported*]
#   Boolean, default 'true'. True means 'collect exported @@balancermember
#    resources' (for the case when every balancermember node exports itself),
#    false means 'rely on the existing declared balancermember resources' (for
#    the case when you know the full set of balancermember in advance and use
#    haproxy::balancermember with array arguments, which allows you to deploy
#    everything in 1 run)
#
# === Examples
#
#  Exporting the resource for a backend member:
#
#  haproxy::backend { 'puppet00':
#    options   => {
#      'option'  => [
#        'tcplog',
#        'ssl-hello-chk'
#      ],
#      'balance' => 'roundrobin'
#    },
#  }
#
# === Authors
#
# Gary Larizza <gary@puppetlabs.com>
# Jeremy Kitchen <jeremy@nationbuilder.com>
#
define haproxy::backend (
  $collect_exported = true,
  $options          = {
    'option'  => [
      'tcplog',
      'ssl-hello-chk'
    ],
    'balance' => 'roundrobin'
  }
) {

  if defined(Haproxy::Listen[$name]) {
    fail("An haproxy::listen resource was discovered with the same name (${name}) which is not supported")
  }

  # Template uses: $name, $ipaddress, $ports, $options
  concat::fragment { "${name}_backend_block":
    order   => "20-${name}-00",
    target  => $::haproxy::config_file,
    content => template('haproxy/haproxy_backend_block.erb'),
  }

  if $collect_exported {
    haproxy::balancermember::collect_exported { $name: }
  }
  # else: the resources have been created and they introduced their
  # concat fragments. We don't have to do anything about them.
}
