notice('MODULAR: openstack-network/networks.pp')

$access_hash           = hiera('access', { })
$keystone_admin_tenant = $access_hash['tenant']
$neutron_config        = hiera_hash('neutron_config')
$segmentation_type     = try_get_value($neutron_config, 'L2/segmentation_type')

$nets = $neutron_config['predefined_networks']

if $segmentation_type == 'vlan' {
  $network_type = 'vlan'
  $segmentation_id_range = split(try_get_value($neutron_config, 'L2/phys_nets/physnet2/vlan_range', ''), ':')
  $fallback_segment_id = $segmentation_id_range[0]
} else {
  $network_type = 'vxlan'
  $segmentation_id_range = split(try_get_value($neutron_config, 'L2/tunnel_id_ranges', ''), ':')
  $fallback_segment_id = $segmentation_id_range[0]
}

openstack::network::create_network { 'net04' :
  netdata             => $nets['net04'],
  segmentation_type   => $network_type,
  tenant_name         => $keystone_admin_tenant,
  fallback_segment_id => $fallback_segment_id,
}

openstack::network::create_network { 'net04_ext' :
  netdata             => $nets['net04_ext'],
  segmentation_type   => 'local',
  tenant_name         => $keystone_admin_tenant,
  fallback_segment_id => $fallback_segment_id,
}
