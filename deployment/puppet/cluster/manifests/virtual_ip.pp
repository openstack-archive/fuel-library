# == Define: cluster::virtual_ip
#
# Configure VirtualIP resource for corosync/pacemaker.
#
# === Parameters
#
# [*key*]
#   Name of virtual IP resource
#
# [*vip*]
#   Specify dictionary of VIP parameters, ex:
#   {
#       bridge => 'br0',
#       ip     => '10.1.1.253'
#   }
#
define cluster::virtual_ip (
  $vip,
  $key = $name,
){

  $vip_name = "vip__${key}"

  if (is_ip_address($vip['gateway']) or ($vip['gateway'] == 'link')) {
    $gateway = $vip['gateway']
  } else {
    $gateway = 'none'
  }

  $parameters = {
    'gateway'              => $gateway,
    'bridge'               => $vip['bridge'],
    'base_veth'            => $vip['base_veth'],
    'ns_veth'              => $vip['ns_veth'],
    'ip'                   => $vip['ip'],
    'iflabel'              => $vip['iflabel'] ? {
      undef   => 'ka',
      default => $vip['iflabel']
    },
    'cidr_netmask'         => $vip['cidr_netmask'] ? {
      undef   => '24',
      default => $vip['cidr_netmask']
    },
    'ns'                   => $vip['namespace'] ? {
      undef   => 'haproxy',
      default => $vip['namespace']
    },
    'gateway_metric'       => $vip['gateway_metric'] ? {
      undef   => undef,
      default => $vip['gateway_metric']
    },
    'other_networks'       => $vip['other_networks'] ? {
      undef => undef, false => undef,
      default => $vip['other_networks']
    },
    'iptables_comment'     => $vip['iptables_comment'] ? {
      undef   => undef, false => undef,
      default => $vip['iptables_comment'],
    },
    'ns_iptables_start_rules' => $vip['ns_iptables_start_rules'] ? {
      undef   => undef, false => undef,
      default => $vip['ns_iptables_start_rules'],
    },
    'ns_iptables_stop_rules'  => $vip['ns_iptables_stop_rules'] ? {
      undef   => undef, false => undef,
      default => $vip['ns_iptables_stop_rules'],
    },
  }

  $metadata = {
    'migration-threshold' => '3',   # will be try start 3 times before migrate to another node
    'failure-timeout'     => '60',  # forget any fails of starts after this timeout
    'resource-stickiness' => '1'
  }

  $operations = {
    'monitor' => {
      'interval' => '5',
      'timeout'  => '20',
    },
    'start'   => {
      'timeout' => '30',
    },
    'stop'    => {
      'timeout' => '30',
    },
  }

  $primitive_type = 'ns_IPaddr2'

  service { $vip_name:
    ensure => 'running',
    enable => true,
  }

  pacemaker_wrappers::service { $vip_name :
    primitive_type => $primitive_type,
    parameters     => $parameters,
    metadata       => $metadata,
    operations     => $operations,
    prefix         => false,
  }

  # I'am running before this other vip
  # and this other vip cannot start without me running on this node
  $colocation_before = $vip['colocation_before']
  if $colocation_before {
    $colocation_before_vip_name = "vip__${colocation_before}"
    $colocation_before_constraint_name = "${colocation_before_vip_name}-with-${vip_name}"
    cs_rsc_colocation { $colocation_before_constraint_name :
      ensure     => 'present',
      score      => 'INFINITY',
      primitives => [
        $colocation_before_vip_name,
        $vip_name,
      ],
    }

    Cs_resource <| title == $vip_name |> -> Cs_resource <| title == $colocation_before_vip_name |>
    Service <| title == $vip_name |> -> Service <| title == $colocation_before_vip_name |>
    Service <| title == $colocation_before_vip_name |> -> Cs_rsc_colocation[$colocation_before_constraint_name]
    Service <| title == $vip_name |> -> Cs_rsc_colocation[$colocation_before_constraint_name]
  }

  # I'm running after this other vip
  # and I cannot start without other vip running on this node
  $colocation_after = $vip['colocation_after']
  if $colocation_after {
    $colocation_after_vip_name = "vip__${colocation_after}"
    $colocation_after_constraint_name = "${vip_name}-with-${colocation_after_vip_name}"
    cs_rsc_colocation { $colocation_after_constraint_name :
      ensure     => 'present',
      score      => 'INFINITY',
      primitives => [
        $vip_name,
        $colocation_after_vip_name,
      ],
    }

    Cs_resource <| title == $colocation_after_vip_name |> -> Cs_resource <| title == $vip_name |>
    Service <| title == $colocation_after_vip_name |> -> Service <| title == $vip_name |>
    Service <| title == $colocation_after_vip_name |> -> Cs_rsc_colocation[$colocation_after_constraint_name]
    Service <| title == $vip_name |> -> Cs_rsc_colocation[$colocation_after_constraint_name]
  }

}

Class['corosync'] -> Cluster::Virtual_ip <||>

if defined(Corosync::Service['pacemaker']) {
  Corosync::Service['pacemaker'] -> Cluster::Virtual_ip <||>
}
