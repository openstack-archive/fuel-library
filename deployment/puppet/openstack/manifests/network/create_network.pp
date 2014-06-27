#Not a docstring
define openstack::network::create_network (
  $netdata
  )
{
  notify {"create network ${name} ::: ${netdata}":}
  neutron_network { $name:
    ensure          => present,
    #physnet         => $netdata['L2']['physnet'],
    #network_type    => $netdata['L2']['network_type'],
    router_external => $netdata['L2']['router_ext'],
    tenant_name     => $netdata['tenant'],
    #segment_id      => $netdata['L2']['segment_id'],
    shared          => $netdata['shared']
  }

  neutron_subnet { "${name}_subnet":
    ensure       => present,
    cidr         => $netdata['L3']['subnet'],
    network_name => $name,
    tenant_name  => $netdata['tenant'],
    #gateway      => $netdata['L3']['gateway'],
    enable_dhcp  => $netdata['L3']['enable_dhcp'],
    #nameservers  => $netdata['L3']['nameservers'],
    #floating     => $netdata['L3']['floating'],
  }
}
