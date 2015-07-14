# Register a service with HAProxy
define openstack::ha::haproxy_service (
  $order,
  $server_names,
  $ipaddresses,
  $listen_port,
  $public_virtual_ip,
  $internal_virtual_ip,

  $mode                   = undef,
  $haproxy_config_options = { 'option' => ['httplog'], 'balance' => 'roundrobin' },
  $balancermember_options = 'check',
  $balancermember_port    = $listen_port,
  $define_cookies         = false,

  # use active-passive failover, mark all backends except the first one
  # as backups
  $define_backups         = false,

  # by default, listen only on internal VIP
  $public                 = false,
  $internal               = true,

  # if defined, restart this service before registering it with HAProxy
  $require_service        = undef,

  # if true, configure this service before starting the haproxy service;
  # HAProxy will refuse to start with no listening services defined
  # But we are using haproxy 'listen Stats' directive, so it can be
  # started w/o this bells and whistles
  $before_start           = false,
) {

  if $public and $internal {
    $virtual_ips = [$public_virtual_ip, $internal_virtual_ip]
  } elsif $internal {
    $virtual_ips = [$internal_virtual_ip]
  } elsif $public {
    $virtual_ips = [$public_virtual_ip]
  }

  haproxy::listen { $name:
    order       => $order,
    ipaddress   => $virtual_ips,
    ports       => $listen_port,
    options     => $haproxy_config_options,
    mode        => $mode,
    use_include => true,
  }

  if $name != "stats" {
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
      command     => 'export OCF_ROOT="/usr/lib/ocf"; (ip netns list | grep haproxy) && ip netns exec haproxy /usr/lib/ocf/resource.d/fuel/ns_haproxy restart',
      path        => '/usr/bin:/usr/sbin:/bin:/sbin',
      logoutput   => true,
      provider    => 'shell',
      tries       => 10,
      try_sleep   => 10,
      returns     => [0, ''],
      require     => [Haproxy::Listen[$name], Haproxy::Balancermember[$name]],
    }
  }
}
