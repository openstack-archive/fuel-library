notice('MODULAR: openstack-network/networks.pp')

if hiera('use_neutron', false) {
  $neutron_config        = hiera_hash('neutron_config')
  $nets                  = $neutron_config['predefined_networks']
  $neutron_floating_net  = pick($neutron_config['default_floating_net'], 'net04_ext')
  $neutron_private_net   = pick($neutron_config['default_private_net'], 'net04')
  $segmentation_type     = try_get_value($neutron_config, 'L2/segmentation_type')

  if $segmentation_type == 'vlan' {
    $network_type = 'vlan'
    $segmentation_id_range = split(try_get_value($neutron_config, 'L2/phys_nets/physnet2/vlan_range', ''), ':')
  } elsif $segmentation_type == 'gre' {
    $network_type = 'gre'
    $segmentation_id_range = split(try_get_value($neutron_config, 'L2/tunnel_id_ranges', ''), ':')
  } else {
    $network_type = 'vxlan'
    $segmentation_id_range = split(try_get_value($neutron_config, 'L2/tunnel_id_ranges', ''), ':')
  }

  create_network($neutron_private_net, $nets[$neutron_private_net], $network_type, $segmentation_id_range )

  create_network($neutron_floating_net, $nets[$neutron_floating_net], 'local')

}
