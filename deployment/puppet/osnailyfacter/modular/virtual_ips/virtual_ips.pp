notice('MODULAR: virtual_ips.pp')

$internal_int                = hiera('internal_int')
$public_int                  = hiera('public_int',  undef)
$primary_controller_nodes    = hiera('primary_controller_nodes', false)
$network_scheme              = hiera('network_scheme', {})
$use_neutron                 = hiera('use_neutron', false)
$deploy_vrouter              = hiera('deploy_vrouter', true)
prepare_network_config(hiera('network_scheme', {}))

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

# todo:(sv): temporary commented. Will be uncommented while 'multiple-l2-network' feature re-implemented
# if $use_neutron {
#   ip_mgmt_other_nets = join($network_scheme['endpoints']["$internal_int"]['other_nets'], ' ')
# }

$management_vip_data = {
  namespace      => 'haproxy',
  nic            => $internal_int,
  base_veth      => "${internal_int}-hapr",
  ns_veth        => "hapr-m",
  ip             => hiera('management_vip'),
  cidr_netmask   => $vip_management_cidr_netmask,
  gateway        => 'none',
  gateway_metric => '0',
  bridge         => get_network_role_property('mgmt/vip', 'interface'),
  other_networks => $vip_mgmt_other_nets,
  with_ping      => false,
  ping_host_list => "",
}

cluster::virtual_ip { 'management' :
  vip => $management_vip_data,
}


if $deploy_vrouter {
  $management_vrouter_vip_data = {
    namespace      => 'vrouter',
    nic            => $internal_int,
    base_veth      => "${internal_int}-vrouter",
    ns             => 'vrouter',
    ns_veth        => 'vr-mgmt',
    ip             => hiera('management_vrouter_vip'),
    cidr_netmask   => $vip_management_cidr_netmask,
    gateway        => 'none',
    gateway_metric => '0',
    bridge         => get_network_role_property('mgmt/vip', 'interface'),
    tie_with_ping  => false,
    ping_host_list => "",
  }

  cluster::virtual_ip { 'management_vrouter' :
    vip => $management_vrouter_vip_data,
  }

  $management_vips = ['management', 'management_vrouter']
} else {
  $management_vips = ['management']
}




if $public_int {
  # todo:(sv): temporary commented. Will be uncommented while 'multiple-l2-network' feature re-implemented
  # if $use_neutron {
  #   vip_publ_other_nets = join($network_scheme['endpoints']["$public_int"]['other_nets'], ' ')
  # }

  $network_role_int =  get_network_role_property('public/vip', 'interface')

  $public_vip_data  = {
    namespace      => 'haproxy',
    nic            => $public_int,
    base_veth      => "${public_int}-hapr",
    ns_veth        => 'hapr-p',
    ip             => hiera('public_vip'),
    cidr_netmask   => $vip_public_cidr_netmask,
    gateway        => $network_scheme['endpoints'][$network_role_int]['gateway'],
    gateway_metric => '10',
    bridge         => $network_role_int,
    other_networks => $vip_publ_other_nets,
  }

  cluster::virtual_ip { 'public' :
    vip => $public_vip_data,
  }


  if $deploy_vrouter {
    $public_vrouter_vip_data = {
      namespace               => 'vrouter',
      nic                     => $public_int,
      base_veth               => "${public_int}-vrouter",
      ns_veth                 => 'vr-ex',
      ns                      => 'vrouter',
      ip                      => hiera('public_vrouter_vip'),
      cidr_netmask            => $vip_public_cidr_netmask,
      gateway                 => $network_scheme['endpoints'][$network_role_int]['gateway'],
      gateway_metric          => '0',
      bridge                  => $network_role_int,
      ns_iptables_start_rules => "iptables -t nat -A POSTROUTING -o vr-ex -j MASQUERADE",
      ns_iptables_stop_rules  => "iptables -t nat -D POSTROUTING -o vr-ex -j MASQUERADE",
      collocation             => 'management_vrouter',
    }

    cluster::virtual_ip { 'public_vrouter' :
      vip => $public_vrouter_vip_data,
    }

    $public_vips = ['public_vip', 'public_vrouter']
  } else {
    $public_vips = ['public_vip']
  }


  $vips = concat($management_vips, $public_vips)
} else {
  $vips = $management_vips
}

#file { 'ns-ipaddr2-ocf':
#  path   =>'/usr/lib/ocf/resource.d/fuel/ns_IPaddr2',
#  mode   => '0755',
#  owner  => 'root',
#  group  => 'root',
#  source => 'puppet:///modules/cluster/ocf/ns_IPaddr2',
#}

# Some topologies might need to keep the vips on the same node during
# deploymenet. This would only need to be changed by hand.
$keep_vips_together = false

if $keep_vips_together {
  cs_rsc_colocation { 'ha_vips':
    ensure      => present,
    primitives  => [prefix($vips, "vip__")],
  }
  Cluster::Virtual_ip[$vips] -> Cs_rsc_colocation['ha_vips']
}

