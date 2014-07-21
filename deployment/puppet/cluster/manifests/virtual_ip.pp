# == Define: cluster::virtual_ip
#
# Configure VirtualIP resource for corosync/pacemaker.
#
# === Parameters
#
# [*name*]
#   Name of virtual IP resource
#
# [*vip*]
#   Specify dictionary of VIP parameters, ex:
#   {
#       nic    => 'eth0',
#       ip     => '10.1.1.253'
#   }
#
define cluster::virtual_ip (
  $vip,
  $key = $name,
){
  $vip_name = "vip__${key}"

  File['ns-ipaddr2-ocf'] -> Cs_resource["${vip_name}"]

  cs_resource { $vip_name:
    ensure          => present,
    primitive_class => 'ocf',
    provided_by     => 'mirantis',
    primitive_type  => 'ns_IPaddr2',
    parameters => {
      'nic'                  => $vip[nic],
      'base_veth'            => $vip[base_veth],
      'ns_veth'              => $vip[ns_veth],
      'ip'                   => $vip[ip],
      'iflabel'              => $vip[iflabel] ? { undef => 'ka', default => $vip[iflabel] },
      'cidr_netmask'         => $vip[cidr_netmask] ? { undef => '24', default => $vip[cidr_netmask] },
      'ns'                   => $vip[namespace] ? { undef => 'haproxy', default => $vip[namespace] },
      'gateway'              => $vip[gateway] ? { undef => '', default => $vip[gateway] },
      'gateway_metric'       => $vip[gateway_metric] ? { undef => '0', default => $vip[gateway_metric] },
      'iptables_start_rules' => $vip[iptables_start_rules] ? { undef => '', default => "'${vip[iptables_start_rules]}'" },
      'iptables_stop_rules'  => $vip[iptables_stop_rules] ? { undef => '', default => "'${vip[iptables_stop_rules]}'" },
      'iptables_comment'     => $vip[iptables_comment] ? { undef => 'default-comment', default => "'${vip[iptables_comment]}'" },
    },
    metadata => {
      'migration-threshold' => '3',   # will be try start 3 times before migrate to another node
      'failure-timeout'     => '60',  # forget any fails of starts after this timeout
      'resource-stickiness' => '1'
    },
    operations => {
      'monitor' => {
        'interval' => '3',
        'timeout'  => '30'
      },
      'start' => {
        'timeout' => '30'
      },
      'stop' => {
        'timeout' => '30'
      },
    },
  }

  service { $vip_name:
    ensure   => 'running',
    enable   => true,
    provider => 'pacemaker',
  }

  Cs_resource[$vip_name] -> Service[$vip_name]

}

Class['corosync'] -> Cluster::Virtual_ip <||>
if defined(Corosync::Service['pacemaker']) {
  Corosync::Service['pacemaker'] -> Cluster::Virtual_ip <||>
}
