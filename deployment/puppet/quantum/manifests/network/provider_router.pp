#
# Use Case: Provider Router with Private Networks
#
define quantum::network::provider_router (
  $quantum_config     = {},
  $router_subnets = undef,
  $router_extnet  = undef
) {
  Quantum_subnet <| |> -> Quantum_router <| |>
  Service <| title == 'keystone' |> -> Quantum_router <| |>

  # create router
  quantum_router { $title:
    #quantum_config  => $quantum_config,
    ensure        => present,
    quantum_config=> $quantum_config,
    int_subnets   => $router_subnets,
    ext_net       => $router_extnet,
    tenant        => $quantum_config['keystone']['admin_tenant_name'],
    auth_url      => $quantum_config['keystone']['auth_url'],
    auth_user     => $quantum_config['keystone']['admin_user'],
    auth_password => $quantum_config['keystone']['admin_password'],
    auth_tenant   => $quantum_config['keystone']['admin_tenant_name'],
  }
}
# vim: set ts=2 sw=2 et :