# == Define: l23network::l2::bridge
#
# Create open vSwitch brigde.
#
# === Parameters
#
# [*name*]
#   Bridge name.
#
# [*skip_existing*]
#   If this bridge already exists it will be ignored without any errors.
#   Must be true or false.
#
# [*external_ids*]
#   See open vSwitch documentation.
#   http://openvswitch.org/cgi-bin/ovsman.cgi?page=utilities%2Fovs-vsctl.8
#
define l23network::l2::bridge (
  $external_ids  = '',
  $ensure        = present,
  $skip_existing = false,
) {
  if ! $::l23network::l2::use_ovs {
    fail('You must enable Open vSwitch by setting the l23network::l2::use_ovs to true.')
  }
  if ! defined (L2_ovs_bridge[$name]) {
    l2_ovs_bridge {$name:
      ensure       => $ensure,
      external_ids => $external_ids,
      skip_existing=> $skip_existing,
    }
    Service<| title == 'openvswitch-service' |> -> L2_ovs_bridge[$name]
  }
}

