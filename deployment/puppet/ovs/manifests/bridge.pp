define ovs::bridge (
  $external_ids = "",
  $ensure = "present",
  $skip_existing = false,
) {
  if ! defined (Ovs_bridge[$name]) {
    ovs_bridge {$name:
      external_ids => $external_ids,
      ensure       => $ensure,
      skip_existing=> $skip_existing,
    }
  }
}

