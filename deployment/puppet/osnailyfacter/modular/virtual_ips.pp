import 'globals.pp'

if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
  $vip_management_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['internal_netmask'])
  $vip_public_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['public_netmask'])

  if $use_neutron {
    $vip_mgmt_other_nets = join($network_scheme['endpoints'][$internal_int]['other_nets'], ' ')
    $ping_host_list = $network_scheme['endpoints']['br-ex']['gateway']
  } else {
    $network_data = hiera('network_data')
    $ping_host_list = $network_data[$public_int]['gateway']
  }

  file { 'ns-ipaddr2-ocf':
    path   =>'/usr/lib/ocf/resource.d/mirantis/ns_IPaddr2',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/cluster/ocf/ns_IPaddr2',
  }

  $vips = { # Do not convert to ARRAY, It can't work in 2.7
    management   => {
      namespace            => 'haproxy',
      nic                  => $::internal_int,
      base_veth            => "${::internal_int}-hapr",
      ns_veth              => "hapr-m",
      ip                   => hiera('management_vip'),
      cidr_netmask         => $vip_management_cidr_netmask,
      gateway              => 'link',
      gateway_metric       => '20',
      other_networks       => $vip_mgmt_other_nets,
      iptables_start_rules => "iptables -t mangle -I PREROUTING -i ${::internal_int}-hapr -j MARK --set-mark 0x2b ; iptables -t nat -I POSTROUTING -m mark --mark 0x2b ! -o ${::internal_int} -j MASQUERADE",
      iptables_stop_rules  => "iptables -t mangle -D PREROUTING -i ${::internal_int}-hapr -j MARK --set-mark 0x2b ; iptables -t nat -D POSTROUTING -m mark --mark 0x2b ! -o ${::internal_int} -j MASQUERADE",
      iptables_comment     => "masquerade-for-management-net",
      tie_with_ping        => false,
      ping_host_list       => "",
    },
  }

  $vips[public] = {
    namespace            => 'haproxy',
    nic                  => $::public_int,
    base_veth            => "${::public_int}-hapr",
    ns_veth              => "hapr-p",
    ip                   => hiera('public_vip'),
    cidr_netmask         => $vip_public_cidr_netmask,
    gateway              => 'link',
    gateway_metric       => '10',
    other_networks       => $vip_publ_other_nets,
    iptables_start_rules => "iptables -t mangle -I PREROUTING -i ${::public_int}-hapr -j MARK --set-mark 0x2a ; iptables -t nat -I POSTROUTING -m mark --mark 0x2a ! -o ${::public_int} -j MASQUERADE",
    iptables_stop_rules  => "iptables -t mangle -D PREROUTING -i ${::public_int}-hapr -j MARK --set-mark 0x2a ; iptables -t nat -D POSTROUTING -m mark --mark 0x2a ! -o ${::public_int} -j MASQUERADE",
    iptables_comment     => "masquerade-for-public-net",
      tie_with_ping        => hiera('run_ping_checker', true),
      ping_host_list       => $ping_host_list,
  }

  $vip_keys = keys($vips)

  cluster::virtual_ips { $vip_keys:
    vips => $vips,
  }
}
