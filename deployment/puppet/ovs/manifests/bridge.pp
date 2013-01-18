define ovs::bridge (
  $external_ids = "",
  $ensure = "present"
) {
  ovs_bridge { $name:
    external_ids => $external_ids,
    ensure       => $ensure
  }
}
