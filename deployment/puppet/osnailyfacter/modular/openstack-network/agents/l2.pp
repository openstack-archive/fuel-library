notice('MODULAR: openstack-network/agents/l2.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {
  $neutron_config = hiera_hash('neutron_config')

  $physnet2_bridge = try_get_value($neutron_config, 'L2/phys_nets/physnet2/bridge')
  $physnet2 = "physnet2:${physnet2_bridge}"
  $bridge_mappings = [$physnet2]

  $network_scheme = hiera_hash('network_scheme')
  prepare_network_config($network_scheme)
  $bind_host = get_network_role_property('neutron/api', 'ipaddr')

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $ha_agent = try_get_value($neutron_advanced_config, 'l2_agent_ha', true)

  $net_role_property = 'neutron/mesh'
  $tunneling_ip = get_network_role_property($net_role_property, 'ipaddr')
  $iface = get_network_role_property($net_role_property, 'phys_dev')
  $physical_net_mtu = pick(get_transformation_property('mtu', $iface[0]), '1500')

  $bridge_vm = get_network_role_property('neutron/private', 'interface')
  $physnet_mtus = regsubst(grep($bridge_mappings, $bridge_vm), $bridge_vm, $physical_net_mtu)

  # TODO: get these values
  class { 'neutron::plugins::ml2':
    type_drivers          => $type_drivers,
    tenant_network_types  => $tenant_network_types,
    mechanism_drivers     => $mechanism_drivers,
    flat_networks         => $flat_networks,
    network_vlan_ranges   => $network_vlan_ranges,
    tunnel_id_ranges      => $tunnel_id_ranges,
    vxlan_group           => $vxlan_group,
    vni_ranges            => $vni_ranges,
    physnet_mtus          => $physnet_mtus,
    path_mtu              => $physical_net_mtu,
  }

  Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-ovs-agent-service' |>
  Service<| title == 'neutron-server' |> -> Service<| title == 'ovs-cleanup-service' |>
  Exec<| title == 'waiting-for-neutron-api' |> -> Service<| title == 'neutron-ovs-agent-service' |>

  if $ha_agent {
    #TODO: refactored agent wrapper
    class { 'cluster::neutron::ovs' :}
  }

}
