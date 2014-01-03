# Register a service with HAProxy
define openstack::ha::haproxy_service (
  $order,
  $server_names,
  $ipaddresses,
  $listen_port,
  $public_virtual_ip,
  $internal_virtual_ip,

  $mode                   = 'tcp',
  $haproxy_config_options = { 'option' => ['httplog'], 'balance' => 'roundrobin' },
  $balancermember_options = 'check',
  $balancermember_port    = $listen_port,
  $define_cookies         = false,
  $define_backups         = false,

  # by default, listen only on internal VIP
  $public                 = false,
  $internal               = true,

  # if defined, restart this service before registering it with HAProxy
  $require_service        = undef,
) {

  if $public and $internal {
    $virtual_ips = [$public_virtual_ip, $internal_virtual_ip]
  } elsif $internal {
    $virtual_ips = [$internal_virtual_ip]
  } elsif $public {
    $virtual_ips = [$public_virtual_ip]
  }

  haproxy::listen { $name:
    order     => $order,
    ipaddress => $virtual_ips,
    ports     => $listen_port,
    options   => $haproxy_config_options,
    mode      => $mode,
  }

  haproxy::balancermember { $name:
    order             => $order,
    listening_service => $name,
    server_names      => $server_names,
    ipaddresses       => $ipaddresses,
    ports             => $balancermember_port,
    options           => $balancermember_options,
    define_cookies    => $define_cookies,
    define_backups    => $define_backups,
  }

  # Dirty hack, due Puppet can't send notify between stages
  exec { "haproxy reload for ${name}":
    command     => 'export OCF_ROOT="/usr/lib/ocf"; /usr/lib/ocf/resource.d/mirantis/haproxy reload',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    logoutput   => true,
    refreshonly => true,
    provider    => 'shell',
    tries       => 3,
    try_sleep   => 1,
    returns     => [0, ''],
    require     => Service['haproxy'],
    subscribe   => [ Haproxy::Listen[$name], Haproxy::Balancermember[$name] ],
  }

  if $require_service {
    Service[$require_service] -> Haproxy::Listen[$name]
  }
}
