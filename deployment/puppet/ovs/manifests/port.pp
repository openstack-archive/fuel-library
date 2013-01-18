define ovs::port (
  $bridge,
  $type   = 'internal',
  $ensure = present
) {
  ovs_port { $name:
    bridge   => $bridge,
    #type     => $type,
    ensure   => $ensure
  }
}
