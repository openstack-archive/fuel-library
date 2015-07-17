notice('MODULAR: ironic_vips.pp')

prepare_network_config(hiera('network_scheme', {}))
$ironic_hash                 = hiera_hash('ironic', {})
$baremetal_int               = get_network_role_property('baremetal/vip', 'interface')
$network_scheme              = hiera('network_scheme', {})
$deploy_vrouter              = hiera('deploy_vrouter', true)

if ( hiera('vip_baremetal_cidr_netmask', false )){
  $vip_baremetal_cidr_netmask = hiera('vip_baremetal_cidr_netmask')
} else {
  $vip_baremetal_cidr_netmask = netmask_to_cidr(get_network_role_property('baremetal/vip', 'netmask'))
}

if $ironic_hash['enabled'] {
  $baremetal_vip_data = {
    namespace            => 'haproxy',
    nic                  => $baremetal_int,
    base_veth            => "br-bare-hapr",
    ns_veth              => "hapr-b",
    ip                   => hiera('baremetal_vip'),
    cidr_netmask         => $vip_baremetal_cidr_netmask,
    gateway              => 'none',
    gateway_metric       => '0',
    bridge               => $baremetal_int,
    other_networks       => $vip_baremetal_other_nets,
    with_ping            => false,
    ping_host_list       => "",
  }

  cluster::virtual_ip { 'baremetal' :
    vip => $baremetal_vip_data,
  }

  if $deploy_vrouter {
    $baremetal_vrouter_vip_data = {
      namespace            => 'vrouter',
      nic                  => $baremetal_int,
      base_veth            => "br-bare-vrouter",
      ns                   => 'vrouter',
      ns_veth              => 'vr-bare',
      ip                   => hiera('baremetal_vrouter_vip'),
      cidr_netmask         => $vip_baremetal_cidr_netmask,
      gateway              => 'none',
      gateway_metric       => '0',
      bridge               => $baremetal_int,
      tie_with_ping        => false,
      ping_host_list       => "",
    }

    cluster::virtual_ip { 'baremetal_vrouter' :
      vip => $baremetal_vrouter_vip_data,
    }
  }
}
