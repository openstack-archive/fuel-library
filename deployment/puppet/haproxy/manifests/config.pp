# == Define Resource Type: haproxy::config
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
# Currently requires the ripienaar/concat module on the Puppet Forge and
#  uses storeconfigs on the Puppet Master to export/collect resources
#  from all balancer members.
#
# === Parameters
#
# [*name*]
#    The namevar of the defined resource type is the listening service's name.
#     This name goes right after the 'listen' statement in haproxy.cfg
#
# [*virtual_ip_port*]
#    A unique port, or a port range for which the proxy will accept connections
#     for the ip address specified in the virtual_ip parameter.
#
# [*order*]
#    The order, or numerical weight, of the fragment created by this defined
#     resource type. This is necessary to ensure the fragment is associated
#     with the correct listening service instance.
#
# [*virtual_ip*]
#    The ip address the proxy binds to. Empty addresses, '*', and '0.0.0.0'
#     mean that the proxy listens to all valid addresses on the system.
#
# [*mode*]
#    The mode of operation for the listening service. Valid values are 'tcp',
#     HTTP', and 'health'.
#
# [*haproxy_config_options*]
#    A hash of options that are inserted into the listening service
#     configuration block.
# 
# [*collect_exported*]
#    Boolean, default 'true'. True means 'collect exported @@balancermember resources'
#    (for the case when every balancermember node exports itself), false means
#    'rely on the existing declared balancermember resources' (for the case when you 
#    know the full set of balancermembers in advance and use haproxy::balancermember 
#    with array arguments, which allows you to deploy everything in 1 run)
#    
#
# === Examples
#
#  Exporting the resource for a balancer member:
#
#  haproxy::config { 'puppet00':
#    order                  => '20',
#    virtual_ip             => $::ipaddress,
#    virtual_ip_port        => '18140',
#    mode                   => 'tcp',
#    haproxy_config_options => {'option' => ['tcplog', 'ssl-hello-chk'],
#                               'balance' => 'roundrobin'},
#  }
#
# === Authors
#
# Gary Larizza <gary@puppetlabs.com>
#
define haproxy::config (
  $virtual_ip_port,
  $order                     = '20',
  $virtual_ip                = $::ipaddress,
  $mode                      = 'tcp',
  $collect_exported          = true,
  $haproxy_config_options    = {
    'option' => [
      'tcplog',
      'ssl-hello-chk'
    ],
    'balance' => 'roundrobin'
  }
) {
  concat::fragment { "${name}_config_block":
    order   => $order,
    target  => '/etc/haproxy/haproxy.cfg',
    content => template('haproxy/haproxy_config_block.erb'),
  }

  if $collect_exported {
    Haproxy::Balancermember <<| listening_service == $name |>>
  }
  # else: the resources have been created and they introduced their
  # concat fragments. We don't have to do anything about them.
}
