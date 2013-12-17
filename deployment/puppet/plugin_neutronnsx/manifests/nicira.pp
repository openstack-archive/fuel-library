class plugin_neutronnsx::nicira (
  $neutron_config = {},
  $ip_address = $::ipaddress,
  $on_compute = false,
  $integration_bridge = 'br-int'
)
{
  if ! $on_compute {
    Anchor<| title=='neutron-server-config-done' |> ->
      Anchor['neutron-plugin-nicira']

    Anchor['neutron-plugin-nicira-done'] ->
      Anchor<| title=='neutron-server-done' |>

  }
  anchor {'neutron-plugin-nicira':}

#Disabling l3 agent
  Cs_colocation <| title == 'dhcp-with-ovs' |> { ensure => absent }
  Cs_order <| title == 'dhcp-afrer-ovs' |> { ensure => absent }
  Neutron_plugin_ovs <||> { noop => true }
  L23network::L2::Bridge <| title == $neutron_config['L2']['integration_bridge'] |> { noop => true}
  Cs_shadow <| title == 'ovs' |> { noop => true }
  Cs_commit <| title == 'ovs' |> { noop => true }
  Cs_resource <| title == "p_${::neutron::params::ovs_agent_service}" |> { noop => true }
  Service <| title == 'neutron-ovs-agent' |> { noop => true }
  Neutron_l3_agent_config <||> { noop => true }
  Service <| title == 'neutron-l3' |> { noop => true }
  Cs_resource <| title == "p_${::neutron::params::l3_agent_service}" |>
  Cs_shadow <| title == 'l2' |>
  Cs_commit <| title == 'l3' |>
  Cs_colocation <| title == 'l3-with-ovs' |> { noop => true }
  Cs_order <| title == 'l3-after-ovs' |> { noop => true }
  Cs_colocation <| title == 'l3-with-metadata' |> { noop => true }
  Cs_order <| title == 'l3-after-metadata' |> { noop => true }
  Cs_colocation <| title == 'dhcp-without-l3' |> { noop => true }
  Service <| title == 'neutron-l3' |> { noop => true }

  Neutron_config <| title == 'DEFAULT/core_plugin' |> {
    value => 'neutron.plugins.nicira.NeutronPlugin.NvpPluginV2'
  }
  package {'nicira-ovs-hypervisor-node':
    ensure => present,
  } ->

  service {'nicira-ovs-hypervisor-node':
    ensure => running,
  }

  if ! $on_compute {
    Neutron_plugin_nicira<||> ~> Service<| title == 'neutron-server' |>
  }
  $br_int = $neutron_config['L2']['integration_bridge']

  l2_nicira_bridge { $br_int:
    external_ids => "bridge-id=${br_int}",
    in_band      => true,
    fail_mode    => 'secure',
  } ->
  l2_ovs_nicira { $::hostname:
    ensure              => present,
    nsx_username        => $neutron_config['nicira']['nsx_username'],
    nsx_password        => $neutron_config['nicira']['nsx_password'],
    nsx_endpoint        => $neutron_config['nicira']['nvp_controllers'],
    transport_zone_uuid => $neutron_config['nicira']['transport_zone_uuid'],
    ip_address          => $ip_address,
    connector_type      => $neutron_config['nicira']['connector_type'],
    integration_bridge  => $integration_bridge,
    notify              => Service['nicira-ovs-hypervisor-node']
  }

  if ! $on_compute {
    if ! defined(File['/etc/neutron']) {
      file {'/etc/neutron':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
      }
    }

    package {'openstack-neutron-nicira':
      ensure => present,
    } ->
    File['/etc/neutron'] ->
    file {'/etc/neutron/plugins/nicira':
      ensure  => directory,
      mode    => '0755',
    } ->
    File <| title == '/etc/neutron/plugin.ini' |> {
      ensure  => link,
      target  => '/etc/neutron/plugins/nicira/nvp.ini',
    } ->
    neutron_plugin_nicira {
      'DATABASE/sql_connection':      value => $neutron_config['database']['url'];
      'DATABASE/sql_max_retries':     value => $neutron_config['database']['reconnects'];
      'DATABASE/reconnect_interval':  value => $neutron_config['database']['reconnect_interval'];
      'DEFAULT/default_tz_uuid':            value => $neutron_config['nicira']['transport_zone_uuid'];
      'DEFAULT/nvp_user':                   value => $neutron_config['nicira']['nsx_username'];
      'DEFAULT/nvp_password':               value => $neutron_config['nicira']['nsx_password'];
      'DEFAULT/req_timeout':                value => 30;
      'DEFAULT/http_timeout':               value => 10;
      'DEFAULT/retries':                    value => 2;
      'DEFAULT/redirects':                  value => 2;
      'DEFAULT/nvp_controllers':            value => $neutron_config['nicira']['nvp_controllers'];
      'DEFAULT/default_l3_gw_service_uuid': value => $neutron_config['nicira']['l3_gw_service_uuid'];
      'quotas/quota_network_gateway':       value => -1;
      'nvp/max_lp_per_bridged_ls':          value => 5000;
      'nvp/max_lp_per_overlay_ls':          value => 256;
      'nvp/metadata_mode':                  value => 'dhcp_host_route';
      'nvp/default_transport_type':         value => $neutron_config['nicira']['connector_type'];
    }
  }
  anchor {'neutron-plugin-nicira-done':}
}
