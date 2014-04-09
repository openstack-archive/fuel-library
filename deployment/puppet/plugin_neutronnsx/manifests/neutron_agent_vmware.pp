class plugin_neutronnsx::neutron_agent_vmware (
  $neutron_nsx_config,
  $ip_address = $::ipaddress,
  $integration_bridge = 'br-int'
)
{
  include plugin_neutronnsx::params

  anchor {'neutron-agent-vmware-start':}
  anchor {'neutron-agent-vmware-end':}

  Anchor<| title=='neutron-server-config-done' |> ->
    Anchor['neutron-agent-vmware-start']

  Anchor['neutron-agent-vmware-end'] ->
    Anchor<| title=='neutron-server-done' |>

  Service <| title == $neutron_plugin_ovs_agent |> {
    ensure => stopped,
  }

  l2_nsx_bridge { $integration_bridge:
    external_ids => "bridge-id=${integration_bridge}",
    in_band      => 'true',
    fail_mode    => 'secure',
  } ->
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
}