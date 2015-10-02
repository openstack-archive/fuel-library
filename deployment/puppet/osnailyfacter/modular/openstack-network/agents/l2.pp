notice('MODULAR: openstack-network/agents/l2.pp')

$use_neutron = hiera('use_neutron', false)

class neutron {}
class { 'neutron' :}

if $use_neutron {
  $neutron_config = hiera_hash('neutron_config')

  $network_scheme = hiera_hash('network_scheme')
  prepare_network_config($network_scheme)

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $ha_agent          = try_get_value($neutron_advanced_config, 'l2_agent_ha', true)
  $l2_population     = try_get_value($neutron_advanced_config, 'neutron_l2_pop', false)
  $dvr               = try_get_value($neutron_advanced_config, 'neutron_dvr', false)
  $segmentation_type = try_get_value($neutron_config, 'L2/segmentation_type')

  if $segmentation_type == 'vlan' {
    $net_role_property    = 'neutron/private'
    $iface                = get_network_role_property($net_role_property, 'phys_dev')
    $physical_net_mtu = pick(get_transformation_property('mtu', $iface[0]), '1500')
    $overlay_net_mtu      = $physical_net_mtu
    $enable_tunneling = false
    $network_vlan_ranges_physnet2 = try_get_value($neutron_config, 'L2/phys_nets/physnet2/vlan_range')
    $network_vlan_ranges = ["physnet2:${$network_vlan_ranges_physnet2}"]
    $physnet2_bridge = try_get_value($neutron_config, 'L2/phys_nets/physnet2/bridge')
    $physnet2 = "physnet2:${physnet2_bridge}"
    $bridge_mappings = [$physnet2]
    $physical_network_mtus = ["physnet2:${physical_net_mtu}"]
    $tunnel_id_ranges = []
  } else {
    $net_role_property = 'neutron/mesh'
    $tunneling_ip      = get_network_role_property($net_role_property, 'ipaddr')
    $iface             = get_network_role_property($net_role_property, 'phys_dev')
    $physical_net_mtu  = pick(get_transformation_property('mtu', $iface[0]), '1500')
    $tunnel_id_ranges  = [try_get_value($neutron_config, 'L2/tunnel_id_ranges')]
    $network_vlan_ranges   = []
    $physical_network_mtus = []

    if $segmentation_type == 'gre' {
      $mtu_offset = '42'
    } else {
    # vxlan is the default segmentation type for non-vlan cases
      $mtu_offset = '50'
    }

    if $physical_net_mtu {
      $overlay_net_mtu = $physical_net_mtu - $mtu_offset
    } else {
      $overlay_net_mtu = '1500' - $mtu_offset
    }

    $enable_tunneling = true

  }

  if $segmentation_type == 'vlan' {
    $network_type = 'vlan'
  } elsif $segmentation_type == 'gre' {
    $network_type = 'gre'
  } else {
    $network_type = 'vxlan'
  }

  if $segmentation_type != 'vlan' {
    $tunnel_types = [$network_type]
  }

  $type_drivers = ['local', 'flat', 'vlan', 'gre', 'vxlan']
  $tenant_network_types  = ['flat', $network_type]
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
    physical_network_mtus => $physical_network_mtus,
    path_mtu              => $overlay_net_mtu,
  }

  class { 'neutron::agents::ml2::ovs':
    bridge_mappings            => $bridge_mappings,
    enable_tunneling           => $enable_tunneling,
    local_ip                   => $tunneling_ip,
    tunnel_types               => $tunnel_types,
    enable_distributed_routing => $dvr,
    l2_population              => $l2_population,
    arp_responder              => $l2_population,
    manage_vswitch             => false,
    manage_service             => true,
    enabled                    => true,
  }

  if $ha_agent {
    $primary_controller = hiera('primary_controller')
    class { 'cluster::neutron::ovs' :
      primary => $primary_controller,
    }
  }

  #========================
  include neutron::params
  package { 'neutron':
    ensure => 'installed',
    name   => $neutron::params::package_name,
    tag    => ['openstack', 'neutron-package'],
  }

}
