# == Define Resource Type: haproxy::frontend
#
# This type will setup a frontend service configuration block inside
#  the haproxy.cfg file on an haproxy load balancer.
#
# === Requirement/Dependencies:
#
# Currently requires the puppetlabs/concat module on the Puppet Forge and
#  uses storeconfigs on the Puppet Master to export/collect resources
#  from all balancer members.
#
# === Parameters
#
# [*name*]
#   The namevar of the defined resource type is the frontend service's name.
#    This name goes right after the 'frontend' statement in haproxy.cfg
#
# [*ports*]
#   Ports on which the proxy will listen for connections on the ip address
#    specified in the ipaddress parameter. Accepts either a single
#    comma-separated string or an array of strings which may be ports or
#    hyphenated port ranges.
#
# [*bind*]
#   Set of ip addresses, port and bind options
#   $bind = { '10.0.0.1:80' => ['ssl', 'crt', '/path/to/my/crt.pem'] }
#
# [*ipaddress*]
#   The ip address the proxy binds to.
#    Empty addresses, '*', and '0.0.0.0' mean that the proxy listens
#    to all valid addresses on the system.
#
# [*mode*]
#   The mode of operation for the frontend service. Valid values are undef,
#    'tcp', 'http', and 'health'.
#
# [*bind_options*]
#   (Deprecated) An array of options to be specified after the bind declaration
#    in the listening serivce's configuration block.
#
# [*options*]
#   A hash of options that are inserted into the frontend service
#    configuration block.
#
# === Examples
#
#  Exporting the resource for a balancer member:
#
#  haproxy::frontend { 'puppet00':
#    ipaddress    => $::ipaddress,
#    ports        => '18140',
#    mode         => 'tcp',
#    bind_options => 'accept-proxy',
#    options      => {
#      'option'   => [
#        'tcplog',
#        'accept-invalid-http-request',
#      ],
#      'timeout client' => '30',
#      'balance'    => 'roundrobin'
#    },
#  }
#
# === Authors
#
# Gary Larizza <gary@puppetlabs.com>
#
define haproxy::frontend (
  $ports            = undef,
  $ipaddress        = undef,
  $bind             = undef,
  $mode             = undef,
  $collect_exported = true,
  $options          = {
    'option'  => [
      'tcplog',
    ],
  },
  # Deprecated
  $bind_options     = '',
) {

  if $ports and $bind {
    fail('The use of $ports and $bind is mutually exclusive, please choose either one')
  }
  if $ipaddress and $bind {
    fail('The use of $ipaddress and $bind is mutually exclusive, please choose either one')
  }
  if $bind_options {
    warning('The $bind_options parameter is deprecated; please use $bind instead')
  }
  if $bind {
    validate_hash($bind)
  }
  # Template uses: $name, $ipaddress, $ports, $options
  concat::fragment { "${name}_frontend_block":
    order   => "15-${name}-00",
    target  => $::haproxy::config_file,
    content => template('haproxy/haproxy_frontend_block.erb'),
  }
}
