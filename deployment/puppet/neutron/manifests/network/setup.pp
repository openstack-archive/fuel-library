#
# Use Case: Provider Router with Private Networks
#
define neutron::network::setup (
  $tenant_name     = 'admin',
  $physnet         = undef,
  $network_type    = 'gre',
  $segment_id      = undef,
  $router_external = 'False',
  $subnet_name     = 'subnet1',
  $subnet_cidr     = '10.47.27.0/24',
  $subnet_gw       = undef,
  $alloc_pool      = undef,
  $enable_dhcp     = 'True',
  $nameservers     = undef,
  $shared          = 'False',
) {

  Neutron_net<||> -> Neutron_subnet<||>
  Service <| title == 'keystone' |> -> Neutron_net <| |>
  Service <| title == 'keystone' |> -> Neutron_subnet <| |>
  # create network
  neutron_net { $title:
    ensure        => present,
    tenant        => $tenant_name,
    physnet       => $physnet,
    network_type  => $network_type,
    segment_id    => $segment_id,
    router_ext    => $router_external,
    shared        => $shared,
  }

  # validate allocation pool
  if $alloc_pool and size($alloc_pool) == 2 {
    $alloc_pool_str = "start=${alloc_pool[0]},end=${alloc_pool[1]}"
  } else {
    $alloc_pool_str = undef
  }

  # create subnet
  neutron_subnet { $subnet_name:
    ensure      => present,
    tenant      => $tenant_name,
    cidr        => $subnet_cidr,
    network     => $title,
    gateway     => $subnet_gw,
    alloc_pool  => $alloc_pool_str,
    enable_dhcp => $enable_dhcp,
    nameservers => $nameservers,
  }

}

# vim: set ts=2 sw=2 et :