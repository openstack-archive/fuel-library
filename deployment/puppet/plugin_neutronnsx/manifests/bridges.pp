class plugin_neutronnsx::bridges (
  $neutron_nsx_config,
  $ip_address = $::ipaddress,
  $integration_bridge = 'br-int'
)
{
  include neutron::params

  anchor {'neutron-agent-vmware-bridges-start':}
  anchor {'neutron-agent-vmware-bridges-end':}

  Anchor<| title=='neutron-server-config-done' |> ->
  Anchor['neutron-agent-vmware-bridges-start']

  Anchor['neutron-agent-vmware-bridges-end'] ->
  Anchor<| title=='neutron-server-done' |>

  l2_nsx_bridge { $integration_bridge:
    external_ids => "bridge-id=${integration_bridge}",
    in_band      => 'true',
    fail_mode    => 'secure',
  }

  l2_ovs_nsx { $::hostname:
    ensure              => present,
    nsx_username        => $neutron_nsx_config['nsx_username'],
    nsx_password        => $neutron_nsx_config['nsx_password'],
    nsx_endpoint        => $neutron_nsx_config['nsx_controllers'],
    transport_zone_uuid => $neutron_nsx_config['transport_zone_uuid'],
    ip_address          => $ip_address,
    connector_type      => $neutron_nsx_config['connector_type'],
    integration_bridge  => $integration_bridge,
  }

  Anchor['neutron-agent-vmware-bridges-start'] ->
  L2_nsx_bridge[$integration_bridge] ->
  L2_ovs_nsx[$::hostname] ->
  Anchor['neutron-agent-vmware-bridges-end']

}