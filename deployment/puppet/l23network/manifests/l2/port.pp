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
  $port          = $name,
  $type          = '',
  $port_properties  = [],
  $interface_properties  = [],
  $ensure        = present,
  $skip_existing = false,
) {
  if ! $::l23network::l2::use_ovs {
    fail('You need enable using Open vSwitch. You yourself has prohibited it.')
  }
  
  if ! defined (L2_ovs_port[$port]) {
    l2_ovs_port { $port :
      ensure        => $ensure,
      bridge        => $bridge,
      type          => $type,
      port_properties  => $port_properties,
      interface_properties  => $interface_properties,
      skip_existing => $skip_existing,
    }
    Service<| title == 'openvswitch-service' |> -> L2_ovs_port[$port]
  }
}
