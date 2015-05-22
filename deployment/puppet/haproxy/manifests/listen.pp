# == Define Resource Type: haproxy::listen
#
# This type will setup a listening service configuration block inside
#  the haproxy.cfg file on an haproxy load balancer. Each listening service
#  configuration needs one or more load balancer member server (that can be
#  declared with the haproxy::balancermember defined resource type). Using
#  storeconfigs, you can export the haproxy::balancermember resources on all
#  load balancer member servers, and then collect them on a single haproxy
#  load balancer server.
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
#   The namevar of the defined resource type is the listening service's name.
#    This name goes right after the 'listen' statement in haproxy.cfg
#
# [*ports*]
#   Ports on which the proxy will listen for connections on the ip address
#    specified in the ipaddress parameter. Accepts either a single
#    comma-separated string or an array of strings which may be ports or
#    hyphenated port ranges.
#
# [*ipaddress*]
#   The ip address the proxy binds to.
#    Empty addresses, '*', and '0.0.0.0' mean that the proxy listens
#    to all valid addresses on the system.
#
# [*bind*]
#   Set of ip addresses, port and bind options
#   $bind = { '10.0.0.1:80' => ['ssl', 'crt', '/path/to/my/crt.pem'] }
#
# [*mode*]
#   The mode of operation for the listening service. Valid values are undef,
#    'tcp', 'http', and 'health'.
#
# [*options*]
#   A hash of options that are inserted into the listening service
#    configuration block.
#
# [*bind_options*]
#   (Deprecated) An array of options to be specified after the bind declaration
#    in the listening serivce's configuration block.
#
# [*collect_exported*]
#   Boolean, default 'true'. True means 'collect exported @@balancermember resources'
#    (for the case when every balancermember node exports itself), false means
#    'rely on the existing declared balancermember resources' (for the case when you
#    know the full set of balancermembers in advance and use haproxy::balancermember
#    with array arguments, which allows you to deploy everything in 1 run)
#
# === Examples
#
#  Exporting the resource for a balancer member:
#
#  haproxy::listen { 'puppet00':
#    ipaddress => $::ipaddress,
#    ports     => '18140',
#    mode      => 'tcp',
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
#
define haproxy::listen (
  $ports                        = undef,
  $ipaddress                    = undef,
  $bind                         = undef,
  $mode                         = undef,
  $collect_exported             = true,
  $order                        = '20',
  $options                      = {
    'option'  => [
      'tcplog',
      'ssl-hello-chk'
    ],
    'balance' => 'roundrobin'
  },
  $use_include                  = $haproxy::params::use_include,
  # Deprecated
  $bind_options                 = '',
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

  if defined(Haproxy::Backend[$name]) {
    fail("An haproxy::backend resource was discovered with the same name (${name}) which is not supported")
  }

  if $use_include {
    $target         = "/etc/haproxy/conf.d/${order}-${name}.cfg"
    $fragment_order = '00'

    concat { $target:
      owner => '0',
      group => '0',
      mode  => '0644',
    }

  } else {
    $target         = '/etc/haproxy/haproxy.conf'
    $fragment_order = "${order}-${name}-00"
  }

  # Template uses: $name, $ipaddress, $ports, $options
  concat::fragment { "${name}_listen_block":
    order   => $fragment_order,
    target  => $target,
    content => template('haproxy/haproxy_listen_block.erb'),
  }

  if $collect_exported {
    haproxy::balancermember::collect_exported { $name: }
  }
  # else: the resources have been created and they introduced their
  # concat fragments. We don't have to do anything about them.
}
