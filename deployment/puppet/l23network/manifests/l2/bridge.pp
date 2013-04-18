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
#   If brigde with this name already exists -- we ignore this fact and
#   don't create bridge without generate error.
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
    fail('You need enable using Open vSwitch. You yourself has prohibited it.')
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

