class neutron::network::predefined_networks (
  $neutron_config     = {},
) {
  create_predefined_networks_and_routers($neutron_config)

  Keystone_user_role<| title=="$auth_user@$auth_tenant"|> -> Neutron_net<| |>
  Service <| title == 'keystone' |> -> Neutron_net <| |>
  Anchor<| title == 'neutron-plugin-ovs-done' |> -> Neutron_net <| |>
  Anchor<| title == 'neutron-plugin-ml2-done' |> -> Neutron_net <| |>

  neutron_floatingip_pool{'admin':
    pool_size => get_floatingip_pool_size_for_admin($neutron_config)
  }
  Neutron_net<||> -> Neutron_floatingip_pool<||>
  Neutron_subnet<||> -> Neutron_floatingip_pool<||>
  Neutron_router<||> -> Neutron_floatingip_pool<||>
}
# vim: set ts=2 sw=2 et :
