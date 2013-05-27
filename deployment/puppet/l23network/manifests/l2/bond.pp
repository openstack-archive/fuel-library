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
#   Bridge that will contain this bond.
#
# [*ports*]
#   List of ports in this bond.
#
# [*skip_existing*]
#   If this bond already exists it will be ignored without any errors.
#   Must be true or false.
#
define l23network::l2::bond (
  $bridge,
  $ports,
  $bond          = $name,
  $properties    = [],
  $ensure        = present,
  $skip_existing = false,
) {
  if ! $::l23network::l2::use_ovs {
    fail('You must enable Open vSwitch by setting the l23network::l2::use_ovs to true.')
  }
  
  if ! defined (L2_ovs_bond["$bond"]) {
    l2_ovs_bond { "$bond" :
      ports         => $ports,
      ensure        => $ensure,
      bridge        => $bridge,
      properties    => $properties,
      skip_existing => $skip_existing,
    }
    Service<| title == 'openvswitch-service' |> -> L2_ovs_bond["$bond"]
  }
}
