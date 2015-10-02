notice('MODULAR: openstack-network/agents/l2.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {
  $neutron_config = hiera_hash('neutron_config')

  $physnet2_bridge = try_get_value($neutron_config, 'L2/phys_nets/physnet2/bridge')
  $network_vlan_ranges = try_get_value($neutron_config, 'L2/phys_nets/physnet2/vlan_range')
  $tunnel_id_ranges = [try_get_value($neutron_config, 'L2/tunnel_id_ranges')]
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
  $segmentation_type = try_get_value($neutron_config, 'L2/segmentation_type')

  if $segmentation_type == 'gre' {
    $network_type = 'gre'
  } else {
    $network_type = 'vxlan'
  }

  $type_drivers = ['local', 'flat', 'vlan', 'gre', 'vxlan']
  $tenant_network_types  = ['flat', 'vlan', $network_type]
  $mechanism_drivers = split(try_get_value($neutron_config, 'L2/mechanism_drivers', 'openvswitch,l2population'), ',')
  $flat_networks = ['*']
  $vxlan_group = '224.0.0.1'

  class { 'neutron::plugins::ml2':
    type_drivers          => $type_drivers,
    tenant_network_types  => $tenant_network_types,
    mechanism_drivers     => $mechanism_drivers,
    flat_networks         => $flat_networks,
    network_vlan_ranges   => $network_vlan_ranges,
    tunnel_id_ranges      => $tunnel_id_ranges,
    vxlan_group           => $vxlan_group,
    vni_ranges            => $tunnel_id_ranges,
    physnet_mtus          => $physnet_mtus,
    path_mtu              => $physical_net_mtu,
  }

# TODO: disabled until new pacemaker merged
#  if $ha_agent {
#    class { 'cluster::neutron::ovs' :}
#  }

}
