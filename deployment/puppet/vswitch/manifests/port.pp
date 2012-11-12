class vswitch::port (
  $interface,
  $bridge,
  $ensure = present
) {
  vs_port { $interface:
    bridge   => $bridge,
    ensure   => $ensure
  }
}
