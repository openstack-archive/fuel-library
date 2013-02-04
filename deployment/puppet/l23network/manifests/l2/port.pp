# == Define: l23network::l2::port
#
# Create open vSwitch port and add to the OVS bridge.
#
# === Parameters
#
# [*name*]
#   Port name.
#
# [*bridge*]
#   Bridge, that will contain this port.
#
# [*type*]
#   Port type. Port type can be
#   'system', 'internal', 'tap', 'gre', 'ipsec_gre', 'capwap', 'patch', 'null'.
#   If you not define type for port (or define '') -- ovs-vsctl will have
#   default behavior while creating port.
#   (see http://openvswitch.org/cgi-bin/ovsman.cgi?page=utilities%2Fovs-vsctl.8)
#
# [*skip_existing*]
#   If this port already exists -- we ignore this fact and
#   don't create it without generate error.
#   Must be true or false.
#
define l23network::l2::port (
  $bridge,
  $type          = '',
  $ensure        = present,
  $skip_existing = false,
) {
  if ! defined (L2_ovs_port[$name]) {
    l2_ovs_port { $name :
      ensure        => $ensure,
      bridge        => $bridge,
      type          => $type,
      skip_existing => $skip_existing,
      require       => Service['openvswitch-service']
    }
  }
}
