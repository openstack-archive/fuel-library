# == Define: l23network::l2::bond
#
# Create open vSwitch port bonding and add to the OVS bridge.
#
# === Parameters
#
# [*name*]
#   Bond name.
#
# [*bridge*]
#   Bridge, that will contain this bond.
#
# [*ports*]
#   List of ports, incoming in this bond.
#
# [*skip_existing*]
#   If this bond already exists -- we ignore this fact and
#   don't create it without generate error.
#   Must be true or false.
#
define l23network::l2::bond (
  $bridge,
  $ports,
  $bond          = $name,
  $options       = [],
  $ensure        = present,
  $skip_existing = false,
) {
  if ! $::l23network::l2::use_ovs {
    fail('You need enable using Open vSwitch. You yourself has prohibited it.')
  }
  
  if ! defined (L2_ovs_bond["$bond"]) {
    l2_ovs_bond { "$bond" :
      ports         => $ports,
      ensure        => $ensure,
      bridge        => $bridge,
      options       => $options,
      skip_existing => $skip_existing,
    }
    Service<| title == 'openvswitch-service' |> -> L2_ovs_bond["$bond"]
  }
}
