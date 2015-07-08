# == Class: openstack::ha::haproxy_service
#
# Register a service with HAProxy
#
# === Paramters
#
# [*internal_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the internal facing
#   vip
#
# [*ipaddresses*]
#   (reqiured) Array. This is an array of ipaddresses for the backend services
#   to be loadbalanced
#
# [*order*]
#   (required) String. Number or string used for configuration file ordering.
#   vip
#
# [*public_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the external facing
#   vip
#
# [*server_names*]
#   (required) Array. This is an array of server names for the haproxy service
#
# [*balancemember_options*]
#   (optional) String or Array. Options for the balancermember configuration.
#   Defaults to 'check'
#
# [*balancemember_port*]
#   (optional) Integer.
#   Defaults to the value of the $listen_port parameter
#
# [*define_backups*]
#   (optional) Boolean. Use active-passive failover, mark all backends except
#   the first one as backups
#   Defaults to false
#
# [*define_cookies*]
#   (optional) Boolean. If true, then add a serviceid cookie for stickiness.
#   Defaults to false
#
# [*haproxy_config_options*]
#   (optional) Hash. HAProxy configuration options for the service.
#   Defaults to { 'option' => ['httplog'], 'balance' => 'roundrobin'}
#
# [*internal*]
#   (optional) Boolean. If set to true listen on the $interanl_vip_ip
#   Defaults to true.
#
# [*mode*]
#   (optional) String. The mode of operation for the service. Valid values are
#   undef, 'tcp', 'http', and 'health'
#   Defaults to undef
#
# [*public*]
#   (optional) Boolean. If set to true  listen on the $public_virtual_ip.
#   Defaults to false.
#
define openstack::ha::haproxy_service (
  $internal_virtual_ip,
  $ipaddresses,
  $listen_port,
  $order,
  $public_virtual_ip,
  $server_names,
  $balancermember_options = 'check',
  $balancermember_port    = $listen_port,
  $define_backups         = false,
  $define_cookies         = false,
  $haproxy_config_options = { 'option' => ['httplog'],
                              'balance' => 'roundrobin' },
  $internal               = true,
  $mode                   = undef,
  $public                 = false,
) {

  validate_boolean($define_backups)
  validate_boolean($define_cookies)
  validate_boolean($public)
  validate_boolean($internal)

  if $public and $internal {
    $virtual_ips = [$public_virtual_ip, $internal_virtual_ip]
  } elsif $internal {
    $virtual_ips = [$internal_virtual_ip]
  } elsif $public {
    $virtual_ips = [$public_virtual_ip]
  } else {
    fail('At least one of $public or $internal must be set to true')
  }

  # Configure HAProxy to listen
  haproxy::listen { $name:
    order       => $order,
    ipaddress   => $virtual_ips,
    ports       => $listen_port,
    options     => $haproxy_config_options,
    mode        => $mode,
    use_include => true,
  }

  # Add balancer memeber to HAProxy
  haproxy::balancermember { $name:
    order             => $order,
    listening_service => $name,
    server_names      => $server_names,
    ipaddresses       => $ipaddresses,
    ports             => $balancermember_port,
    options           => $balancermember_options,
    define_cookies    => $define_cookies,
    define_backups    => $define_backups,
    use_include       => true,
  }

  # Dirty hack, due Puppet can't send notify between stages
  exec { "haproxy restart for ${name}":
    command   => 'export OCF_ROOT="/usr/lib/ocf"; (ip netns list | grep haproxy) && ip netns exec haproxy /usr/lib/ocf/resource.d/fuel/ns_haproxy restart',
    path      => '/usr/bin:/usr/sbin:/bin:/sbin',
    logoutput => true,
    provider  => 'shell',
    tries     => 10,
    try_sleep => 10,
    returns   => [0, ''],
    require   => [Haproxy::Listen[$name], Haproxy::Balancermember[$name]],
  }
}
