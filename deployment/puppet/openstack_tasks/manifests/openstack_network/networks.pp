class openstack_tasks::openstack_network::networks {

  notice('MODULAR: openstack_network/networks.pp')

  $access_hash           = hiera_hash('access', {})
  $keystone_admin_tenant = $access_hash['tenant']
  $neutron_config        = hiera_hash('neutron_config')
  $floating_net          = dig($neutron_config, ['default_floating_net'], 'net04_ext')
  $private_net           = dig($neutron_config, ['default_private_net'], 'net04')
  $default_router        = dig($neutron_config, ['default_router'], 'router04')
  $segmentation_type     = dig($neutron_config, ['L2', 'segmentation_type'])
  $nets                  = $neutron_config['predefined_networks']

  if $segmentation_type == 'vlan' {
    $network_type = 'vlan'
    $segmentation_id_range = split(dig($neutron_config, ['L2', 'phys_nets', 'physnet2', 'vlan_range'], ''), ':')
  } elsif $segmentation_type == 'gre' {
    $network_type = 'gre'
    $segmentation_id_range = split(dig($neutron_config, ['L2', 'tunnel_id_ranges'], ''), ':')
  } else {
    $network_type = 'vxlan'
    $segmentation_id_range = split(dig($neutron_config, ['L2', 'tunnel_id_ranges'], ''), ':')
  }

  $fallback_segment_id          = $segmentation_id_range[0]
  $private_net_segment_id       = dig($nets, [$private_net, 'L2', 'segment_id'], $fallback_segment_id)
  $private_net_physnet          = dig($nets, [$private_net, 'L2', 'physnet'], false)
  $private_net_shared           = dig($nets, [$private_net, 'shared'], false)
  $private_net_router_external  = false
  $floating_net_type            = dig($nets, [$floating_net, 'L2', 'network_type'], 'local')
  $floating_net_physnet         = $floating_net_type ? {
                                      'local' => false,
                                      default => dig($nets, [$floating_net, 'L2', 'physnet'], false),
                                  }
  $floating_net_router_external = dig($nets, [$floating_net, 'L2', 'router_ext'])
  $floating_net_floating_range  = dig($nets, [$floating_net, 'L3', 'floating'], '')
  $floating_net_shared          = dig($nets, [$floating_net, 'shared'], false)

  if !empty($floating_net_floating_range) {
    $floating_cidr = dig($nets, [$floating_net, 'L3', 'subnet'])
    $floating_net_allocation_pool = format_allocation_pools($floating_net_floating_range, $floating_cidr)
  }

  $tenant_name         = dig($access_hash, ['tenant'], 'admin')

  neutron_network { $floating_net :
    ensure                    => 'present',
    provider_physical_network => $floating_net_physnet,
    provider_network_type     => $floating_net_type,
    router_external           => $floating_net_router_external,
    tenant_name               => $tenant_name,
    shared                    => $floating_net_shared
  }

  neutron_subnet { "${floating_net}__subnet" :
    ensure           => 'present',
    cidr             => dig($nets, [$floating_net, 'L3', 'subnet']),
    network_name     => $floating_net,
    tenant_name      => $tenant_name,
    gateway_ip       => dig($nets, [$floating_net, 'L3', 'gateway']),
    enable_dhcp      => false,
    allocation_pools => $floating_net_allocation_pool,
  }

  neutron_network { $private_net :
    ensure                    => 'present',
    provider_physical_network => $private_net_physnet,
    provider_network_type     => $network_type,
    provider_segmentation_id  => $private_net_segment_id,
    router_external           => $private_net_router_external,
    tenant_name               => $tenant_name,
    shared                    => $private_net_shared
  }

  neutron_subnet { "${private_net}__subnet" :
    ensure          => 'present',
    cidr            => dig($nets, [$private_net, 'L3', 'subnet']),
    network_name    => $private_net,
    tenant_name     => $tenant_name,
    gateway_ip      => dig($nets, [$private_net, 'L3', 'gateway']),
    enable_dhcp     => true,
    dns_nameservers => dig($nets, [$private_net, 'L3', 'nameservers']),
  }

  if has_key($nets, 'baremetal') {
    $baremetal_physnet         = dig($nets, ['baremetal', 'L2', 'physnet'], false)
    $baremetal_segment_id      = dig($nets, ['baremetal', 'L2', 'segment_id'])
    $baremetal_router_external = dig($nets, ['baremetal', 'L2', 'router_ext'])
    $baremetal_shared          = dig($nets, ['baremetal', 'shared'], false)

    neutron_network { 'baremetal' :
      ensure                    => 'present',
      provider_physical_network => $baremetal_physnet,
      provider_network_type     => 'flat',
      provider_segmentation_id  => $baremetal_segment_id,
      router_external           => $baremetal_router_external,
      tenant_name               => $tenant_name,
      shared                    => $baremetal_shared
    }

    neutron_subnet { 'baremetal__subnet' :
      ensure           => 'present',
      cidr             => dig($nets, ['baremetal', 'L3', 'subnet']),
      network_name     => 'baremetal',
      tenant_name      => $tenant_name,
      gateway_ip       => dig($nets, ['baremetal', 'L3', 'gateway']),
      enable_dhcp      => true,
      dns_nameservers  => dig($nets, ['baremetal', 'L3', 'nameservers']),
      allocation_pools => format_allocation_pools(dig($nets, ['baremetal', 'L3', 'floating'])),
    }
  }
}
