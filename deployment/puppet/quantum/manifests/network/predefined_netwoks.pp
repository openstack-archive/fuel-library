class quantum::network::predefined_netwoks (
  $quantum_config     = {},
) {

  # $nets_and_rou = create_predefined_networks_and_routers($quantum_config)
  # notify {"networks_and_routers: ${nets_and_rou}": }
  create_predefined_networks_and_routers($quantum_config)

  Keystone_user_role<| title=="$auth_user@$auth_tenant"|> -> Quantum::Network::Setup <| |>
  Keystone_user_role<| title=="$auth_user@$auth_tenant"|> -> Quantum::Network::Provider_router <| |>

  # quantum::network::provider_router { 'router04':
  #   router_subnets => 'subnet04',
  #   router_extnet  => 'net04_ext',
  #   auth_tenant    => $quantum_config['keystone']['admin_tenant_name'],
  #   auth_user      => $quantum_config['keystone']['admin_user'],
  #   auth_password  => $quantum_config['keystone']['admin_password'],
  #   auth_url       => $quantum_config['keystone']['auth_url']
  # }
  #Quantum::Network::Provider_router<||> -> Service<| title=='quantum-l3' |>
}
# vim: set ts=2 sw=2 et :