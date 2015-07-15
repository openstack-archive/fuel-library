notice('MODULAR: ironic_vips.pp')

$ironic_hash                 = hiera('ironic')
$internal_int                = hiera('internal_int')
$primary_controller_nodes    = hiera('primary_controller_nodes', false)
$network_scheme              = hiera('network_scheme', {})
$deploy_vrouter              = hiera('deploy_vrouter', true)

if ( hiera('vip_baremetal_cidr_netmask', false )){
  $vip_baremetal_cidr_netmask = hiera('vip_baremetal_cidr_netmask')
} else {
  $vip_baremetal_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['internal_netmask'])
}

if $ironic_hash['enabled'] {
  $baremetal_vip_data = {
    namespace            => 'haproxy',
    nic                  => $internal_int,
    base_veth            => "br-bare-hapr",
    ns_veth              => "hapr-b",
    ip                   => hiera('baremetal_vip'),
    cidr_netmask         => $vip_baremetal_cidr_netmask,
    gateway              => 'none',
    gateway_metric       => '0',
    bridge               => $network_scheme['roles']['baremetal'],
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
      nic                  => $internal_int,
      base_veth            => "br-bare-vrouter",
      ns                   => 'vrouter',
      ns_veth              => 'vr-bare',
      ip                   => hiera('baremetal_vrouter_vip'),
      cidr_netmask         => $vip_baremetal_cidr_netmask,
      gateway              => 'none',
      gateway_metric       => '0',
      bridge               => $network_scheme['roles']['baremetal'],
      tie_with_ping        => false,
      ping_host_list       => "",
    }

    cluster::virtual_ip { 'baremetal_vrouter' :
      vip => $baremetal_vrouter_vip_data,
    }
  }
}
