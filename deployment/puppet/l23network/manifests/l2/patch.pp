# == Define: l23network::l2::patch
#
# Connect two open vSwitch bridges by virtual patch-cord.
#
# === Parameters
# [*bridges*]
#   Bridges that will be connected.
#
# [*peers*]
#   Patch port names for both bridges. must be array of two strings.
#
# [*tags*]
#   Specify 802.1q tag for each end of patchcord. Must be array of 2 integers.
#   Default [0,0] -- untagged
#
# [*trunks*]
#   Specify array of 802.1q tags (identical for both ends) if need configure patch in trunk mode.
#   Define trunks => [0] if you need pass only untagged traffic.
#   by default -- undefined.
#
# [*skip_existing*]
#   If this patch already exists it will be ignored without any errors.
#   Must be true or false.
#
define l23network::l2::patch (
  $bridges,
  $peers         = [undef,undef],
  $tags          = [0, 0],
  $trunks        = [],
  $provider      = 'ovs',
  $ensure        = present,
  $skip_existing = false
) {
  if ! $::l23network::l2::use_ovs {
    fail('You must enable Open vSwitch by setting the l23network::l2::use_ovs to true.')
  }

  # Architecture limitation.
  # We can't create more one patch between same bridges.
  #$patch = "${bridges[0]}_${tags[0]}--${bridges[1]}_${tags[1]}"
  $patch = "${bridges[0]}--${bridges[1]}"

  if ! defined (L2_ovs_patch["$patch"]) {
    l2_ovs_patch { "$patch" :
      bridges       => $bridges,
      peers         => $peers,
      tags          => $tags,
      trunks        => $trunks,
      ensure        => $ensure
    }
    Service<| title == 'openvswitch-service' |> -> L2_ovs_patch["$patch"]
  }
}
