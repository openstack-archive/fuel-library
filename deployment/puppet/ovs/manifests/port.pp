define ovs::port (
  $bridge,
  $type      = '',
  $ensure    = present,
  $may_exist = false,
) {
  if ! defined (Ovs_port[$name]) {
    ovs_port { $name :
      bridge    => $bridge,
      ensure    => $ensure,
      type      => $type,
      may_exist => $may_exist,
    }
  }
}
