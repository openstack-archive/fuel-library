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
  $cib_name = "vip__${key}"
  $vip_name = "vip__${key}"

  # OCF script for pacemaker
  # and his dependences
  file {'ns-ipaddr2-ocf':
    path   =>'/usr/lib/ocf/resource.d/mirantis/ns_IPaddr2',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/cluster/ns_IPaddr2",
  }

  Package['pacemaker'] -> File['ns-ipaddr2-ocf']
  File<| title == 'ocf-mirantis-path' |> -> File['ns-ipaddr2-ocf']
  File['ns-ipaddr2-ocf'] -> Cs_resource["${vip_name}"]


  cs_shadow { $cib_name: cib => $cib_name }
  cs_commit { $cib_name: cib => $cib_name }

  cs_resource { $vip_name:
    ensure          => present,
    cib             => $cib_name,
    primitive_class => 'ocf',
    provided_by     => 'mirantis',
    primitive_type  => 'ns_IPaddr2',
    parameters => {
      'nic'          => $vip[nic],
      'ip'           => $vip[ip],
      'iflabel'      => $vip[iflabel] ? { undef => 'ka', default => $vip[iflabel] },
      'cidr_netmask' => $vip[cidr_netmask] ? { undef => '24', default => $vip[cidr_netmask] },
      'ns'           => $vip[namespace] ? { undef => 'haproxy', default => $vip[namespace] },
    },
    metadata => {
      'resource-stickiness' => '1',
    },
    operations => {
      'monitor' => {
        'interval' => '2',
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
}

Class['corosync'] -> Cluster::Virtual_ip <||>
if defined(Corosync::Service['pacemaker']) {
  Corosync::Service['pacemaker'] -> Cluster::Virtual_ip <||>
}
#
###
