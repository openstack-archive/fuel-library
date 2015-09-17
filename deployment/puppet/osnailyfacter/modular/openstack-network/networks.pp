notice('MODULAR: openstack-network/networks.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {

  $access_hash           = hiera('access', { })
  $keystone_admin_tenant = $access_hash['tenant']
  $neutron_config        = hiera_hash('neutron_config')
  $segmentation_type     = try_get_value($neutron_config, 'L2/segmentation_type')

  $nets = $neutron_config['predefined_networks']

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

  $net04_ext_physnet     = try_get_value($nets, 'net04_ext/L2/physnet', false)
  $net04_physnet         = try_get_value($nets, 'net04/L2/physnet', false)

  $net04_ext_router_external = try_get_value($nets, 'net04_ext/L2/router_ext')
  $net04_router_external     = false

  $net04_ext_shared      = try_get_value($nets, 'net04_ext/shared', false)
  $net04_shared          = false

  $tenant_name           = try_get_value($access_hash, 'tenant', 'admin')

  neutron_network { 'net04_ext' :
    ensure                    => 'present',
    provider_physical_network => $net04_ext_physnet,
    provider_network_type     => 'local',
    router_external           => $net04_ext_router_external,
    tenant_name               => $tenant_name,
    shared                    => $net04_ext_shared
  } ->

  neutron_subnet { 'net04_ext__subnet' :
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
    provider_network_type     => $network_type,
    provider_segmentation_id  => $net04_segment_id,
    router_external           => $net04_router_external,
    tenant_name               => $tenant_name,
    shared                    => $net04_shared
  } ->

  neutron_subnet { 'net04__subnet' :
    ensure          => 'present',
    cidr            => try_get_value($nets, 'net04/L3/subnet'),
    network_name    => 'net04',
    tenant_name     => $tenant_name,
    gateway_ip      => try_get_value($nets, 'net04/L3/gateway'),
    enable_dhcp     => true,
    dns_nameservers => try_get_value($nets, 'net04/L3/nameservers'),
  }

  if has_key($nets, 'baremetal') {
    $baremetal_physnet         = try_get_value($nets, 'baremetal/L2/physnet', false)
    $baremetal_segment_id      = try_get_value($nets, 'baremetal/L2/segment_id')
    $baremetal_router_external = try_get_value($nets, 'baremetal/L2/router_ext')
    $baremetal_shared          = try_get_value($nets, 'baremetal/shared', false)

    neutron_network { 'baremetal' :
      ensure                    => 'present',
      provider_physical_network => $baremetal_physnet,
      provider_network_type     => 'flat',
      provider_segmentation_id  => $baremetal_segment_id,
      router_external           => $baremetal_router_external,
      tenant_name               => $tenant_name,
      shared                    => $baremetal_shared
    } ->

    neutron_subnet { 'baremetal__subnet' :
      ensure          => 'present',
      cidr            => try_get_value($nets, 'baremetal/L3/subnet'),
      network_name    => 'baremetal',
      tenant_name     => $tenant_name,
      gateway_ip      => try_get_value($nets, 'baremetal/L3/gateway'),
      enable_dhcp     => true,
      dns_nameservers => try_get_value($nets, 'baremetal/L3/nameservers'),
    } ->

    neutron_router_interface { "router04:baremetal__subnet":
      ensure => 'present',
    }
  }

}
