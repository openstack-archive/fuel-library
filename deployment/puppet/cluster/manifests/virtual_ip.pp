# == Define: cluster::virtual_ip
#
# Configure VirtualIP resource for corosync/pacemaker.
#
# [*bridge*]
#   (Required) Name of the bridge that has network
#   namespace with VIP connected to it.
#
# [*ip*]
#   (Required) The IPv4 address to be configured in
#   dotted quad notation.
#
# [*ns_veth*]
#   (Required) Name of network namespace side of
#   the veth pair.
#
# [*base_veth*]
#   (Required) Name of base system side of
#   the veth pair.
#
# [*gateway*]
#   Default route address.
#   Default: none
#
# [*iflabel*]
#   You can specify an additional label for your IP address here.
#   This label is appended to your interface name.
#   Defualt: ka
#
# [*cidr_netmask*]
#   The netmask for the interface in CIDR format.
#   Default: 24
#
# [*ns*]
#   Name of network namespace.
#   Default: haproxy
#
# [*gateway_metric*]
#   The metric value of the default route.
#
# [*other_networks*]
#   Additional routes that should be added to this resource.
#   Routes will be added via value ns_veth.
#   Should be space separated list of networks in CIDR format.
#
# [*iptables_comment*]
#   Iptables comment to associate with rules.
#
# [*ns_iptables_start_rules*]
#   Iptables rules that should be
#   started along with IP in the namespace.
#
# [*ns_iptables_stop_rules*]
#   Iptables rules that should be
#   stopped along with IP in the namespace.
#
# [*also_check_interfaces*]
#   Network interfaces list (ex. NIC), that should be in
#   UP state for monitor action returns succesful.
#
# [*primitive_type*]
#   The name of the OCF script to use.
#   Default: ns_IPaddr2
#
# [*use_pcmk_prefix*]
#   Should the 'p_' prefix be added to
#   the primitive name.
#   Default: false
#
# [*vip_prefix*]
#   The prefix added to the VIP primitive name.
#   Default: 'vip__'
#
# [*additional_parameters*]
#   Any additional instance variables can be
#   passed as a hash here.
#   Default: {}
#
# [*colocation_before*]
#   The name of an other virtual_ip instance
#   that should have a colocation constraint to
#   go before this virtual_ip.
#
# [*colocation_after*]
#   The name of an other virtual_ip instance
#   that should have a colocation constraint to
#   go after this virtual_ip.
#
# [*colocation_score*]
#   The score of the created colocation constraints.
#   Default: INFINITY
#
# [*colocation_ensure*]
#   Controlls the ensure value of the colocations.
#   Default: present
#
# [*colocation_separator*]
#   The separator between vip names in the colocation
#   constraint name.
#   Default: -with-
#
define cluster::virtual_ip (
  $bridge,
  $ip,
  $ns_veth,
  $base_veth,
  $gateway                 = 'none',
  $iflabel                 = 'ka',
  $cidr_netmask            = '24',
  $ns                      = 'haproxy',
  $gateway_metric          = undef,
  $other_networks          = undef,
  $iptables_comment        = undef,
  $ns_iptables_start_rules = undef,
  $ns_iptables_stop_rules  = undef,
  $also_check_interfaces   = undef,
  $primitive_type          = 'ns_IPaddr2',
  $use_pcmk_prefix         = false,
  $vip_prefix              = 'vip__',
  $additional_parameters   = { },
  $colocation_before       = undef,
  $colocation_after        = undef,
  $colocation_score        = 'INFINITY',
  $colocation_ensure       = 'present',
  $colocation_separator    = '-with-',
){
  validate_string($primitive_type)
  validate_bool($use_pcmk_prefix)
  validate_hash($additional_parameters)

  $vip_name = "${vip_prefix}${name}"

  $metadata = {
    # will try to start 3 times before migrating to another node
    'migration-threshold' => '3',
    # forget any start failures after this timeout
    'failure-timeout'     => '60',
    # will not randomly migrate to the other nodes without a reason
    'resource-stickiness' => '1',
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
    $additional_parameters
  )

  service { $vip_name:
    ensure => 'running',
    enable => true,
  }

  pacemaker::service { $vip_name :
    primitive_type => $primitive_type,
    parameters     => $parameters,
    metadata       => $metadata,
    operations     => $operations,
    prefix         => $use_pcmk_prefix,
  }

  # I'am running before this other vip
  # and this other vip cannot start without me running on this node
  if $colocation_before {
    $colocation_before_vip_name = "${vip_prefix}${colocation_before}"
    $colocation_before_constraint_name = "${colocation_before_vip_name}${colocation_separator}${vip_name}"
    pcmk_colocation { $colocation_before_constraint_name :
      ensure => $colocation_ensure,
      score  => $colocation_score,
      first  => $vip_name,
      second => $colocation_before_vip_name,
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
      ensure => $colocation_ensure,
      score  => $colocation_score,
      first  => $colocation_after_vip_name,
      second => $vip_name,
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
