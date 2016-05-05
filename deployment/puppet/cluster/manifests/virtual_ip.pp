# == Define: cluster::virtual_ip
#
# Configure VirtualIP resource for corosync/pacemaker.
#
define cluster::virtual_ip (
  $bridge,
  $ip,
  $ns_veth,
  $gateway = 'none',
  $base_veth = undef,
  $iflabel = 'ka',
  $cidr_netmask = '24',
  $ns = 'haproxy',
  $gateway_metric = undef,
  $other_networks = undef,
  $iptables_comment = undef,
  $ns_iptables_start_rules = undef,
  $ns_iptables_stop_rules = undef,
  $also_check_interfaces = undef,
  $primitive_type = 'ns_IPaddr2',
  $use_pcmk_prefix = false,
  $vip_prefix = 'vip__',
  $additional_parameters = {},
  $colocation_before = undef,
  $colocation_after = undef,
  $colocation_score = 'INFINITY',
  $colocation_ensure = 'present',
  $colocation_separator = '-with-',
){
  validate_string($primitive_type)
  validate_bool($use_pcmk_prefix)
  validate_hash($additional_parameters)

  $vip_name = "${vip_prefix}${name}"

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
      'interval' => '0',
      'timeout'  => '30',
    },
    'stop'    => {
      'interval' => '0',
      'timeout'  => '30',
    },
  }

  $parameters = resource_parameters(
    'bridge', $bridge,
    'ip', $ip,
    'cidr_netmask', $cidr_netmask,
    'iflabel', $iflabel,
    'ns', $ns,
    'base_veth', $base_veth,
    'ns_veth', $ns_veth,
    'gateway', $gateway,
    'gateway_metric', $gateway_metric,
    'ns_iptables_start_rules', $ns_iptables_start_rules,
    'ns_iptables_stop_rules', $ns_iptables_stop_rules,
    'iptables_comment', $iptables_comment,
    'also_check_interfaces', $also_check_interfaces,
    'other_networks', $other_networks,
    $additional_parameters,
  )

  service { $vip_name:
    ensure => 'running',
    enable => true,
  }

  pacemaker::service { $vip_name :
    primitive_type   => $primitive_type,
    parameters       => $parameters,
    metadata         => $metadata,
    operations       => $operations,
    prefix           => $use_pcmk_prefix,
  }

  # I'am running before this other vip
  # and this other vip cannot start without me running on this node
  if $colocation_before {
    $colocation_before_vip_name = "${vip_prefix}${colocation_before}"
    $colocation_before_constraint_name = "${colocation_before_vip_name}${colocation_separator}${vip_name}"
    pcmk_colocation { $colocation_before_constraint_name :
      ensure     => $colocation_ensure,
      score      => $colocation_score,
      first      => $vip_name,
      second     => $colocation_before_vip_name,
    }

    Pcmk_resource <| title == $vip_name |> -> Pcmk_resource <| title == $colocation_before_vip_name |>
    Service <| title == $vip_name |> -> Service <| title == $colocation_before_vip_name |>
    Service <| title == $colocation_before_vip_name |> -> Pcmk_colocation[$colocation_before_constraint_name]
    Service <| title == $vip_name |> -> Pcmk_colocation[$colocation_before_constraint_name]
  }

  # I'm running after this other vip
  # and I cannot start without other vip running on this node
  if $colocation_after {
    $colocation_after_vip_name = "${vip_prefix}${colocation_after}"
    $colocation_after_constraint_name = "${vip_name}${colocation_separator}${colocation_after_vip_name}"
    pcmk_colocation { $colocation_after_constraint_name :
      ensure     => $colocation_ensure,
      score      => $colocation_score,
      first      => $colocation_after_vip_name,
      second     => $vip_name,
    }

    Pcmk_resource <| title == $colocation_after_vip_name |> -> Pcmk_resource <| title == $vip_name |>
    Service <| title == $colocation_after_vip_name |> -> Service <| title == $vip_name |>
    Service <| title == $colocation_after_vip_name |> -> Pcmk_colocation[$colocation_after_constraint_name]
    Service <| title == $vip_name |> -> Pcmk_colocation[$colocation_after_constraint_name]
  }

}

Class['corosync'] -> Cluster::Virtual_ip <||>

if defined(Corosync::Service['pacemaker']) {
  Corosync::Service['pacemaker'] -> Cluster::Virtual_ip <||>
}
