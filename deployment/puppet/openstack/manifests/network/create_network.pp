#Not a docstring
define openstack::network::create_network (
  $netdata,
  $fallback_segment_id = 1
  )
{
  notify {"create network ${name} ::: ${netdata}":}

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

  notify {"${name} ::: ${netdata['L2']['physnet']}":}
  notify {"${name} ::: ${netdata['L2']['network_type']}":}
  notify {"${name} ::: ${netdata['L2']['router_ext']}":}
  notify {"${name} ::: ${netdata['tenant']}":}
  notify {"${name} ::: ${$netdata['shared']}":}

  neutron_network { $name:
    ensure                    => present,
    provider_physical_network => $netdata['L2']['physnet'],
    provider_network_type     => $netdata['L2']['network_type'],
    provider_segmentation_id  => $segment_id,
    router_external           => $netdata['L2']['router_ext'],
    tenant_name               => $netdata['tenant'],
    shared                    => $netdata['shared']
  }

  neutron_subnet { "${name}_subnet":
    ensure          => present,
    cidr            => $netdata['L3']['subnet'],
    network_name    => $name,
    tenant_name     => $netdata['tenant'],
    gateway_ip      => $netdata['L3']['gateway'],
    enable_dhcp     => $netdata['L3']['enable_dhcp'],
    dns_nameservers => $netdata['L3']['nameservers'],
    allocation_pools=> $allocation_pools,
  }
}
