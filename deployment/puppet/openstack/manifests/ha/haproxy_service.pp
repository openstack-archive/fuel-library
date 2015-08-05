# == Type: openstack::ha::haproxy_service
#
# Register a service with HAProxy
#
# === Parameters
#
# [*internal_virtual_ip*]
#   (required) Array or Single value. This is the ipaddress to be used for the internal facing
#   vip
#
# [*ipaddresses*]
#   (optional) Array. This is an array of ipaddresses for the backend services
#   to be loadbalanced
#
# [*order*]
#   (required) String. Number or string used for configuration file ordering.
#   vip
#
# [*public_virtual_ip*]
#   (optional) String. This is the ipaddress to be used for the external facing
#   vip
#
# [*server_names*]
#   (optional) Array. This is an array of server names for the haproxy service
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
#   (optional) Boolean. If true, listen on the $public_virtual_ip.
#   Defaults to false.
#
# [*public_ssl*]
#   (optional) Boolean. If true, enable SSL on $public_virtual_ip.
#   Defaults to false.
# [*require_service*]
#   (optional) Boolean. If true, refresh service before registering in HAProxy.
#   Defaults to false.
# [*before_start*]
#   (optional) Boolean. If true, service is configured before starting HAProxy service.
#   This will cause an error if service does not start. Usually not needed for
#   'listen Stats' directive.
#   Defaults to false.
define openstack::ha::haproxy_service (
  $internal_virtual_ip,
  $listen_port,
  $order,
  $public_virtual_ip      = undef,
  $balancermember_options = 'check',
  $balancermember_port    = $listen_port,
  $before_start           = false,
  $define_backups         = false,
  $define_cookies         = false,
  $haproxy_config_options = { 'option' => ['httplog'],
                              'balance' => 'roundrobin' },
  $internal               = true,
  $public                 = false,
  $public_ssl             = false,
  $ipaddresses            = undef,
  $server_names           = undef,
  $mode                   = undef,
  $require_service        = undef,
) {

  validate_bool($define_backups)
  validate_bool($define_cookies)
  validate_bool($public)
  validate_bool($internal)

  if $public and $internal {
    if $public_ssl {
      $bind = merge({ "$public_virtual_ip:$listen_port" => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'] },
              array_to_hash(suffix(flatten([$internal_virtual_ip]), ":${listen_port}"), ""))
    } else {
      $bind = array_to_hash(suffix(flatten([$internal_virtual_ip, $public_virtual_ip]), ":${listen_port}"), "")
    }
  } elsif $internal {
    $bind = array_to_hash(suffix(flatten([$internal_virtual_ip]), ":${listen_port}"), "")
  } elsif $public {
    if $public_ssl {
      $bind = { "$public_virtual_ip:$listen_port" => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'] }
    } else {
      $bind = array_to_hash(suffix(flatten([$public_virtual_ip]), ":${listen_port}"), "")
    }
  } else {
    fail('At least one of $public or $internal must be set to true')
  }

  # Configure HAProxy to listen
  haproxy::listen { $name:
    order       => $order,
    bind        => $bind,
    options     => $haproxy_config_options,
    mode        => $mode,
    use_include => true,
  }

  if $ipaddresses and $server_names {
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
      before            => Exec["haproxy restart for ${name}"],
    }
  }

  # Dirty hack, due Puppet can't send notify between stages
  exec { "haproxy restart for ${name}":
    command     => 'export OCF_ROOT="/usr/lib/ocf"; (ip netns list | grep haproxy) && ip netns exec haproxy /usr/lib/ocf/resource.d/fuel/ns_haproxy restart',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    logoutput   => true,
    provider    => 'shell',
    tries       => 10,
    try_sleep   => 10,
    returns     => [0, ''],
    require     => Haproxy::Listen[$name],
  }
}
