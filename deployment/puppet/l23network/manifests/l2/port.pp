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
#   Bridge that will contain this port.
#
# [*type*]
#   Port type can be set to one of the following values:
#   'system', 'internal', 'tap', 'gre', 'ipsec_gre', 'capwap', 'patch', 'null'.
#   If you do not define of leave this value empty then ovs-vsctl will create
#   the port with default behavior.
#   (see http://openvswitch.org/cgi-bin/ovsman.cgi?page=utilities%2Fovs-vsctl.8)
#
# [*tag*]
#   Specify 802.1q tag for result bond. If need.
#
# [*trunks*]
#   Specify array of 802.1q tags if need configure bond in trunk mode.
#   Define trunks => [0] if you need pass only untagged traffic.
#
# [*skip_existing*]
#   If this port already exists it will be ignored without any errors.
#   Must be true or false.
#
define l23network::l2::port (
  $bridge,
  $port                  = $name,
  $type                  = '',
  $port_properties       = [],
  $interface_properties  = [],
  $tag                   = 0,
  $trunks                = [],
  $vlan_splinters        = false,
  $provider              = 'ovs',
  $ensure                = present,
  $skip_existing         = false
) {
  if ! $::l23network::l2::use_ovs {
    fail('You must enable Open vSwitch by setting the l23network::l2::use_ovs to true.')
  }

  if ! defined (L2_ovs_port[$port]) {
    l2_ovs_port { $port :
      ensure               => $ensure,
      bridge               => $bridge,
      type                 => $type,
      tag                  => $tag,
      trunks               => $trunks,
      vlan_splinters       => $vlan_splinters,
      port_properties      => $port_properties,
      interface_properties => $interface_properties,
      skip_existing        => $skip_existing
    }
    Service<| title == 'openvswitch-service' |> -> L2_ovs_port[$port]
  }
}
