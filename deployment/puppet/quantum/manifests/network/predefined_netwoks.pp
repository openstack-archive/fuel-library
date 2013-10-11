class quantum::network::predefined_netwoks (
  $quantum_config     = {},
) {
  create_predefined_networks_and_routers($quantum_config)

  Keystone_user_role<| title=="$auth_user@$auth_tenant"|> -> Quantum_net<| |>
  Service <| title == 'keystone' |> -> Quantum_net <| |>
  Anchor['quantum-plugin-ovs-done'] -> Quantum_net <| |>
}
# vim: set ts=2 sw=2 et :