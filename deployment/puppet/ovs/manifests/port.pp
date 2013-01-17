define ovs::port (
  $interface,
  $bridge,
  $ensure = present
) {
  ovs_port { $interface:
    bridge   => $bridge,
    ensure   => $ensure
  }
}
