#
# ==Parameters
# [network] ipv4 CIDR of network to create. Required.
# [num_networks] Number of networks to split $network into. Optional
#   Defaults to 1.
# [project] Project that network should be associated with.
#
define nova::manage::network (
  $network,
  $num_networks = 1,
  $network_size = 255,
  $project = undef
) {

  File['/etc/nova/nova.conf'] -> Nova_network[$name]
  Exec<| title == 'nova-db-sync' |> -> Nova_network[$name]

  nova_network { $name:
    ensure       => present,
    network      => $network,
    num_networks => $num_networks,
    network_size => $network_size,
    project      => $project,
  }

}
