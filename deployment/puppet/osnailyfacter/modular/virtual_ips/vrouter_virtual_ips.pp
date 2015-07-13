notice('MODULAR: vrouter_virtual_ips.pp')

$internal_int                = hiera('internal_int')
$public_int                  = hiera('public_int',  undef)
$primary_controller_nodes    = hiera('primary_controller_nodes', false)
$network_scheme              = hiera('network_scheme', {})
$deploy_vrouter              = hiera('deploy_vrouter', true)

if ( hiera('vip_management_cidr_netmask', false )){
  $vip_management_cidr_netmask = hiera('vip_management_cidr_netmask')
} else {
  $vip_management_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['internal_netmask'])
}
if ( hiera('vip_public_cidr_netmask', false )){
  $vip_public_cidr_netmask     = hiera('vip_public_cidr_netmask')
} else {
  $vip_public_cidr_netmask     = netmask_to_cidr($primary_controller_nodes[0]['public_netmask'])
}

if $deploy_vrouter {
  $management_vrouter_vip_data = {
    namespace            => 'vrouter',
    nic                  => $internal_int,
    base_veth            => "${internal_int}-vrouter",
    ns                   => 'vrouter',
    ns_veth              => 'vr-mgmt',
    ip                   => hiera('management_vrouter_vip'),
    cidr_netmask         => $vip_management_cidr_netmask,
    gateway              => 'none',
    gateway_metric       => '0',
    bridge               => $network_scheme['roles']['management'],
    tie_with_ping        => false,
    ping_host_list       => "",
  }

  cluster::virtual_ip { 'management_vrouter' :
    vip => $management_vrouter_vip_data,
  }

  $public_vrouter_vip_data = {
    namespace               => 'vrouter',
    nic                     => $public_int,
    base_veth               => "${public_int}-vrouter",
    ns_veth                 => 'vr-ex',
    ns                      => 'vrouter',
    ip                      => hiera('public_vrouter_vip'),
    cidr_netmask            => $vip_public_cidr_netmask,
    gateway                 => $network_scheme['endpoints']['br-ex']['gateway'],
    gateway_metric          => '0',
    bridge                  => $network_scheme['roles']['ex'],
    ns_iptables_start_rules => "iptables -t nat -A POSTROUTING -o vr-ex -j MASQUERADE",
    ns_iptables_stop_rules  => "iptables -t nat -D POSTROUTING -o vr-ex -j MASQUERADE",
    collocation             => 'management_vrouter',
  }

  cluster::virtual_ip { 'public_vrouter' :
    vip => $public_vrouter_vip_data,
  }
}
