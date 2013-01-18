define ovs::bridge (
  $external_ids = "",
  $ensure = "present"
) {
  if ! defined (Ovs_bridge[$name]) {
    ovs_bridge {$name:
      external_ids => $external_ids,
      ensure       => $ensure,
    }
  }
}

