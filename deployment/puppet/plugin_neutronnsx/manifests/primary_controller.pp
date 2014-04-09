class plugin_neutronnsx::primary_controller (
  $neutron_nsx_config,
)
{
#  anchor {'neutron-vmware-prim_ctrlr-start':}
#  anchor {'neutron-vmware-prim_ctrlr-end':}

#  Anchor<| title=='neutron-server-config-done' |> ->
#    Anchor['neutron-vmware-prim_ctrlr-start']

  # Anchor['neutron-vmware-prim_ctrlr-end'] ->
  #   Anchor<| title=='neutron-server-done' |>

  Neutron_net <| title == 'net04' |> {
    router_ext   => false,
    network_type => false,
    physnet      => false,
    segment_id   => false,
  }
  Neutron_net <| title == 'net04_ext' |> {
    router_ext   => true,
    network_type => 'l3_ext',
    physnet      => $neutron_nsx_config['l3_gw_service_uuid'],
    segment_id   => false,
  }
  Neutron_subnet <| title == 'net04__subnet' |> {
    gateway => false,
  }
}