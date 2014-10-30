#Not a docstring
define openstack::network::create_network (
  $netdata,
  $tenant_name   = 'admin',
  $fallback_segment_id = 1
  )
{

  # FIXME(xarses): clean up sanitization and move business logic to nailgun

  if $netdata['L2']['network_type'] in ['vlan', 'gre', 'vxlan'] {
    if $netdata['L2']['segment_id'] =~ /^$/ {
      $segment_id = $fallback_segment_id
    } else {
      $segment_id = $netdata['L2']['segment_id']
    }
  }

  if $netdata['L3']['floating'] {
    $alloc = split($netdata['L3']['floating'], ':')
    $allocation_pools = "start=${alloc[0]},end=${alloc[1]}"
  }

  if $netdata['L2']['physnet'] {
    $physnet = $netdata['L2']['physnet']
  } else {
    $physnet = false
  }
  notify {"${name} ::: physnet ${physnet}":}
  notify {"${name} ::: network_type ${netdata['L2']['network_type']}":}
  notify {"${name} ::: router_ext ${netdata['L2']['router_ext']}":}
  notify {"${name} ::: tenant ${netdata['tenant']}":}
  notify {"${name} ::: shared ${$netdata['shared']}":}

  neutron_network { $name:
    ensure                    => present,
    provider_physical_network => $physnet,
    provider_network_type     => $netdata['L2']['network_type'],
    provider_segmentation_id  => $segment_id,
    router_external           => $netdata['L2']['router_ext'],
    tenant_name               => $tenant_name,
    shared                    => $netdata['shared']
  }

  neutron_subnet { "${name}__subnet":
    ensure          => present,
    cidr            => $netdata['L3']['subnet'],
    network_name    => $name,
    tenant_name     => $tenant_name,
    gateway_ip      => $netdata['L3']['gateway'],
    enable_dhcp     => $netdata['L3']['enable_dhcp'],
    dns_nameservers => $netdata['L3']['nameservers'],
    allocation_pools=> $allocation_pools,
  }
}
