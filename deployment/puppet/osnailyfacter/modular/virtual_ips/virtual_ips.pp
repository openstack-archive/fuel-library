notice('MODULAR: virtual_ips.pp')


$internal_int                = hiera('internal_int')
$public_int                  = hiera('public_int',  undef)
$primary_controller_nodes    = hiera('primary_controller_nodes', false)
$network_scheme              = hiera('network_scheme', {})
$vip_management_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['internal_netmask'])
$vip_public_cidr_netmask     = netmask_to_cidr($primary_controller_nodes[0]['public_netmask'])
$use_neutron                 = hiera('use_neutron')

if $use_neutron {
  $vip_mgmt_other_nets = join($network_scheme['endpoints']["$internal_int"]['other_nets'], ' ')
}

$vips = { # Do not convert to ARRAY, It can't work in 2.7
  management   => {
    namespace            => 'haproxy',
    nic                  => $internal_int,
    base_veth            => "${internal_int}-hapr",
    ns_veth              => "hapr-m",
    ip                   => hiera('management_vip'),
    cidr_netmask         => $vip_management_cidr_netmask,
    gateway              => 'link',
    gateway_metric       => '20',
    other_networks       => $vip_mgmt_other_nets,
    iptables_start_rules => "iptables -t mangle -I PREROUTING -i ${internal_int}-hapr -j MARK --set-mark 0x2b ; iptables -t nat -I POSTROUTING -m mark --mark 0x2b ! -o ${internal_int} -j MASQUERADE",
    iptables_stop_rules  => "iptables -t mangle -D PREROUTING -i ${internal_int}-hapr -j MARK --set-mark 0x2b ; iptables -t nat -D POSTROUTING -m mark --mark 0x2b ! -o ${internal_int} -j MASQUERADE",
    iptables_comment     => "masquerade-for-management-net",
    tie_with_ping        => false,
    ping_host_list       => "",
  },
}

if $public_int {
  if $use_neutron{
    $vip_publ_other_nets = join($network_scheme['endpoints']["$public_int"]['other_nets'], ' ')
  }

  $vips[public] = {
    namespace            => 'haproxy',
    nic                  => $public_int,
    base_veth            => "${public_int}-hapr",
    ns_veth              => "hapr-p",
    ip                   => hiera('public_vip'),
    cidr_netmask         => $vip_public_cidr_netmask,
    gateway              => 'link',
    gateway_metric       => '10',
    other_networks       => $vip_publ_other_nets,
    iptables_start_rules => "iptables -t mangle -I PREROUTING -i ${public_int}-hapr -j MARK --set-mark 0x2a ; iptables -t nat -I POSTROUTING -m mark --mark 0x2a ! -o ${public_int} -j MASQUERADE",
    iptables_stop_rules  => "iptables -t mangle -D PREROUTING -i ${public_int}-hapr -j MARK --set-mark 0x2a ; iptables -t nat -D POSTROUTING -m mark --mark 0x2a ! -o ${public_int} -j MASQUERADE",
    iptables_comment     => "masquerade-for-public-net",
    tie_with_ping        => hiera('run_ping_checker', true),
    ping_host_list       => $network_scheme['endpoints']['br-ex']['gateway'],
  }
}
$vip_keys = keys($vips)

class virtual_ips () {
  file { 'ns-ipaddr2-ocf':
    path   =>'/usr/lib/ocf/resource.d/fuel/ns_IPaddr2',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/cluster/ocf/ns_IPaddr2',
  }

  cluster::virtual_ips { $::vip_keys:
    vips => $::vips,
  }

  # Some topologies might need to keep the vips on the same node during
  # deploymenet. This would only need to be changed by hand.
  $keep_vips_together = false
  if ($keep_vips_together) {
    cs_rsc_colocation { 'ha_vips':
      ensure      => present,
      primitives  => [prefix(keys($::vips),"vip__")],
      after       => Cluster::Virtual_ips[$::vip_keys]
    }
  } # End If keep_vips_together
}

class { 'virtual_ips': }
