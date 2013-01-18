define ovs::port (
  $bridge,
  $type   = '',
  $ensure = present,
) {
  if ! defined (Ovs_port[$name]) {
    ovs_port { $name :
      bridge   => $bridge,
      ensure => $ensure,
      type => $type,
    }
  }
}
