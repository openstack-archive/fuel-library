define ovs::port (
  $bridge,
  $type      = '',
  $ensure    = present,
  $skip_existing = false,
) {
  if ! defined (Ovs_port[$name]) {
    ovs_port { $name :
      bridge    => $bridge,
      ensure    => $ensure,
      type      => $type,
      skip_existing => $skip_existing,
    }
  }
}
