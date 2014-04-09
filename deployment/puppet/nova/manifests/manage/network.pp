#
# ==Parameters
# [network] ipv4 CIDR of network to create. Required.
# [num_networks] Number of networks to split $network into. Optional
#   Defaults to 1.
# [project] Project that network should be associated with.
#
define nova::manage::network (
  $network,
  $label        = 'novanetwork',
  $num_networks = 1,
  $network_size = 255,
  $vlan_start   = undef,
  $project      = undef
) {

  File['/etc/nova/nova.conf'] -> Nova_network[$name]
  Exec<| title == 'nova-db-sync' |> -> Nova_network[$name]

  nova_network { $name:
    ensure       => present,
    network      => $network,
    label        => $label,
    num_networks => $num_networks,
    network_size => $network_size,
    project      => $project,
    vlan_start   => $vlan_start,
  }

}
