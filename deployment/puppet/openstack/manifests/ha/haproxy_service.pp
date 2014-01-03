# Register a service with HAProxy
define openstack::ha::haproxy_service (
  $order,
  $balancers,
  $port,
  $public_virtual_ip,
  $internal_virtual_ip,

  $balancer_port    = $port,
  $mode             = 'tcp',
  $define_cookies   = false,
  $define_backend   = false,
  $collect_exported = false,

  # by default, listen only on internal VIP
  $public           = false,
  $internal         = true,

  # if defined, restart this service before registering it with HAProxy
  $service          = undef,

  $haproxy_config_options = { 'option' => ['httplog'], 'balance' => 'roundrobin' },
  $balancermember_options = 'check',
) {

  if $public and $internal {
    $virtual_ips = [$public_virtual_ip, $internal_virtual_ip]
  } elsif $internal {
    $virtual_ips = [$internal_virtual_ip]
  } elsif $public {
    $virtual_ips = [$public_virtual_ip]
  }

  haproxy::listen { $name:
    order            => $order - 1,
    ipaddress        => $virtual_ips,
    ports            => $port,
    options          => $haproxy_config_options,
    collect_exported => $collect_exported,
    mode             => $mode,
  }

  @haproxy::balancermember { $name:
    order                  => $order,
    listening_service      => $name,
    balancers              => $balancers,
    balancer_port          => $balancer_port,
    balancermember_options => $balancermember_options,
    define_cookies         => $define_cookies,
    define_backend         => $define_backend,
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
  }

  if $service {
    Service[$service] -> Haproxy::Listen[$name]
  }

  Haproxy::Listen[$name] ->
  Haproxy::Balancermember[$name] ~>
  Exec["haproxy reload for ${name}"]
}
