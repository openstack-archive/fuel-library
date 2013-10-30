class quantum::network::predefined_netwoks (
  $quantum_config     = {},
) {
  create_predefined_networks_and_routers($quantum_config)

  Keystone_user_role<| title=="$auth_user@$auth_tenant"|> -> Quantum_net<| |>
  Service <| title == 'keystone' |> -> Quantum_net <| |>
  Anchor['quantum-plugin-ovs-done'] -> Quantum_net <| |>

  quantum_floatingip_pool{'admin':
    pool_size => get_floatingip_pool_size_for_admin($quantum_config)
  }
  Quantum_net<||> -> Quantum_floatingip_pool<||>
  Quantum_subnet<||> -> Quantum_floatingip_pool<||>
  Quantum_router<||> -> Quantum_floatingip_pool<||>
}
# vim: set ts=2 sw=2 et :