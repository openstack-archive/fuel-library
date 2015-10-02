notice('MODULAR: openstack-network/networks.pp')

$access_hash           = hiera('access', { })
$keystone_admin_tenant = $access_hash['tenant']
$neutron_config        = hiera_hash('neutron_config')
$segmentation_type     = try_get_value($neutron_config, 'L2/segmentation_type')

$nets = $neutron_config['predefined_networks']

if $segmentation_type == 'vlan' {
  $network_type = 'vlan'
  $segmentation_id_range = split(try_get_value($neutron_config, 'L2/phys_nets/physnet2/vlan_range', ''), ':')
} else {
  $network_type = 'vxlan'
  $segmentation_id_range = split(try_get_value($neutron_config, 'L2/tunnel_id_ranges', ''), ':')
}

$fallback_segment_id = $segmentation_id_range[0]

$net04_ext_segment_id  = try_get_value($nets, 'net04_ext/L2/segment_id', $fallback_segment_id)
$net04_segment_id      = try_get_value($nets, 'net04/L2/segment_id', $fallback_segment_id)

$net04_ext_floating_range = split(try_get_value($nets, 'net04_ext/L3/floating', ''), ':')
$net04_floating_range     = split(try_get_value($nets, 'net04/L3/floating', ''), ':')

if !empty($net04_ext_floating_range) {
  $net04_ext_floating_range_start = $net04_ext_floating_range[0]
  $net04_ext_floating_range_end   = $net04_ext_floating_range[1]
  $net04_ext_allocation_pool = "start=${net04_ext_floating_range_start},end=${net04_ext_floating_range_end}"
}

echo($nets, 'NETS')

$net04_ext_physnet     = try_get_value($nets, 'net04_ext/L2/physnet', undef)
$net04_physnet         = try_get_value($nets, 'net04/L2/physnet', undef)

$net04_ext_router_external = try_get_value($nets, 'net04_ext/L2/router_ext')
$net04_router_external     = undef

$net04_ext_shared      = try_get_value($nets, 'net04_ext/shared', false)
$net04_shared          = undef

$tenant_name           = try_get_value($access_hash, 'tenant', 'admin')

neutron_network { 'net04_ext' :
  ensure                    => 'present',
  provider_physical_network => $net04_ext_physnet,
  provider_network_type     => $segmentation_type,
  provider_segmentation_id  => $net04_ext_segment_id,
  router_external           => $net04_ext_router_external,
  tenant_name               => $tenant_name,
  shared                    => $net04_ext_shared
} ->

neutron_subnet { 'net04_ext_subnet' :
  ensure           => 'present',
  cidr             => try_get_value($nets, 'net04_ext/L3/subnet'),
  network_name     => 'net04_ext',
  tenant_name      => $tenant_name,
  gateway_ip       => try_get_value($nets, 'net04_ext/L3/gateway'),
  enable_dhcp      => false,
  allocation_pools => $net04_ext_allocation_pool,
}

neutron_network { 'net04' :
  ensure                    => 'present',
  provider_physical_network => $net04_physnet,
  provider_network_type     => $segmentation_type,
  provider_segmentation_id  => $net04_segment_id,
  router_external           => $net04_router_external,
  tenant_name               => $tenant_name,
  shared                    => $net04_shared
} ->

neutron_subnet { 'net04_subnet' :
  ensure          => 'present',
  cidr            => try_get_value($nets, 'net04/L3/subnet'),
  network_name    => 'net04_ext',
  tenant_name     => $tenant_name,
  gateway_ip      => try_get_value($nets, 'net04/L3/gateway'),
  enable_dhcp     => true,
  dns_nameservers => try_get_value($nets, 'net04/L3/nameservers'),
}
