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
# [*interfaces*]
#   List of interfaces in this bond.
#
# [*tag*]
#   Specify 802.1q tag for result bond. If need.
#
# [*trunks*]
#   Specify array of 802.1q tags if need configure bond in trunk mode.
#   Define trunks => [0] if you need pass only untagged traffic.
#
# [*skip_existing*]
#   If this bond already exists it will be ignored without any errors.
#   Must be true or false.
#
define l23network::l2::bond (
  $bridge,
  $interfaces    = undef,
  $ports         = undef, # deprecated, must be used interfaces
  $bond          = $name,
  $properties    = [],
  $tag           = 0,
  $trunks        = [],
  $provider      = 'ovs',
  $ensure        = present,
  $skip_existing = false
) {
  if ! $::l23network::l2::use_ovs {
    fail('You must enable Open vSwitch by setting the l23network::l2::use_ovs to true.')
  }

  if $interfaces {
    $r_interfaces = $interfaces
  } elsif $ports {
    $r_interfaces = $ports
  } else {
    fail("You must specify 'interfaces' property for this bond.")
  }

  if ! defined (L2_ovs_bond["$bond"]) {
    l2_ovs_bond { "$bond" :
      ensure        => $ensure,
      interfaces    => $r_interfaces,
      bridge        => $bridge,
      tag           => $tag,
      trunks        => $trunks,
      properties    => $properties,
      skip_existing => $skip_existing,
    }
    Service<| title == 'openvswitch-service' |> -> L2_ovs_bond["$bond"]
  }
}
