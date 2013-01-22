define ovs::bridge (
  $external_ids = "",
  $ensure = "present",
  $may_exist = false,
) {
  if ! defined (Ovs_bridge[$name]) {
    ovs_bridge {$name:
      external_ids => $external_ids,
      ensure       => $ensure,
      may_exist    => $may_exist,
    }
  }
}

