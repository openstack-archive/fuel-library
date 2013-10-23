#
# Use Case: Provider Router with Private Networks
#
define neutron::network::provider_router (
  $neutron_config     = {},
  $router_subnets = undef,
  $router_extnet  = undef
) {
  Neutron_subnet <| |> -> Neutron_router <| |>
  Service <| title == 'keystone' |> -> Neutron_router <| |>

  # create router
  neutron_router { $title:
    ensure        => present,
    neutron_config=> $neutron_config,
    int_subnets   => $router_subnets,
    ext_net       => $router_extnet,
    tenant        => $neutron_config['keystone']['admin_tenant_name'],
    auth_url      => $neutron_config['keystone']['auth_url'],
    auth_user     => $neutron_config['keystone']['admin_user'],
    auth_password => $neutron_config['keystone']['admin_password'],
    auth_tenant   => $neutron_config['keystone']['admin_tenant_name'],
  }
}
# vim: set ts=2 sw=2 et :