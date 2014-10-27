# Not a doc string
define openstack::network::create_router (
  $internal_network,
  $external_network,
  $tenant_name = 'admin',
  $virtual     = false,
  ) {

  Neutron_subnet <| title == "${external_network}__subnet" |> ->

  neutron_router { $name:
    ensure               => present,
    tenant_name          => $tenant_name,
    gateway_network_name => $external_network,
  } ->

  neutron_router_interface { "${name}:${internal_network}__subnet":
    ensure => present,
  }
}
