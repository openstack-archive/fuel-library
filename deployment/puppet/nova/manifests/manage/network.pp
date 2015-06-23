# === Parameters:
#
# [*network*]
#   (required) IPv4 CIDR of network to create.
#
# [*label*]
#   (optional) The label of the network.
#   Defaults to 'novanetwork'.
#
# [*num_networks*]
#   (optional) Number of networks to split $network into.
#   Defaults to 1
#
# [*network_size*]
#   (optional) Size of the network to create
#   Defaults to 255
#
# [*vlan_start*]
#   (optional) The vlan number to use if in vlan mode
#   Defaults to undef
#
# [*project*]
#   (optional) Project that network should be associated with
#   Defaults to undef
#
# [*dns1*]
#   (optional) First DNS server
#   Defaults to '8.8.8.8'
#
# [*dns2*]
#   (optional) Second DNS server
#   Defaults to '8.8.4.4'
#
define nova::manage::network (
  $network,
  $label        = 'novanetwork',
  $num_networks = 1,
  $network_size = 255,
  $vlan_start   = undef,
  $project      = undef,
  $dns1         = '8.8.8.8',
  $dns2         = '8.8.4.4',
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
    dns1         => $dns1,
    dns2         => $dns2,
  }

}
