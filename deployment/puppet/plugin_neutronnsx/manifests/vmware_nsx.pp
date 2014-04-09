class plugin_neutronnsx::vmware_nsx (
  $neutron_config = {},
  $ip_address = $::ipaddress,
  $on_compute = false,
  $integration_bridge = 'br-int'
)
{
  include plugin_neutronnsx::params

  if ! $on_compute {
    Anchor<| title=='neutron-server-config-done' |> ->
      Anchor['neutron-plugin-vmware']

    Anchor['neutron-plugin-vmware-done'] ->
      Anchor<| title=='neutron-server-done' |>
    if $::osfamily =~ /(?i)debian/ {
      exec { 'enable_plugin':
        command => "/bin/sed -i 's/^NEUTRON_PLUGIN_CONFIG.*/NEUTRON_PLUGIN_CONFIG=\/etc\/neutron\/plugin.ini/g' /etc/default/neutron-server",
      }
      Package<| title == $::neutron::params::server_package |> -> Exec['enable_plugin'] ~> Service<| title == 'neutron-server' |>
    }

  }
  anchor {'neutron-plugin-vmware':}

  Service <| title == 'openvswitch-service' |>

  Neutron_net <| title == 'net04' |> {
    router_ext   => false,
    network_type => false,
    physnet      => false,
    segment_id   => false,
  }
  Neutron_net <| title == 'net04_ext' |> {
    router_ext   => true,
    network_type => 'l3_ext',
    physnet      => $neutron_config['nsx']['l3_gw_service_uuid'],
    segment_id   => false,
  }
  Neutron_subnet <| title == 'net04__subnet' |> {
    gateway => false,
  }
# Neutron_subnet <||> { noop => true }
# Neutron_router <||> { noop => true }
# Neutron_floatingip_pool <||> { noop => true }
# Disabling l3 agent
  Service <| title == 'neutron-plugin-openvswitch-agent' |> {
    ensure => stopped,
  }
  Neutron_l3_agent_config <||> { noop => true }
  Cs_colocation <| title == 'l3-with-ovs' |> { noop => true }
  Cs_order <| title == 'l3-after-ovs' |> { noop => true }
  Cs_colocation <| title == 'l3-with-metadata' |> { noop => true }
  Cs_order <| title == 'l3-after-metadata' |> { noop => true }
  Cs_colocation <| title == 'dhcp-without-l3' |> { noop => true }
  Service <| title == 'neutron-l3' |> {
    ensure => stopped,
  }
  Neutron_config <| title == 'DEFAULT/core_plugin' |> {
    value => 'vmware',
  }
  Neutron_dhcp_agent_config <| title == 'DEFAULT/enable_isolated_metadata' |> {
    value => 'true',
  }
  Neutron_dhcp_agent_config <| title == 'DEFAULT/enable_metadata_network' |> {
    value => 'true',
  }

  if ! $on_compute {
    Neutron_plugin_vmware<||> ~> Service<| title == 'neutron-server' |>
  }

  $br_int = $neutron_config['L2']['integration_bridge']
  l2_nsx_bridge { $br_int:
    external_ids => "bridge-id=${br_int}",
    in_band      => 'true',
    fail_mode    => 'secure',
  } ->
  l2_ovs_nsx { $::hostname:
    ensure              => present,
    nsx_username        => $neutron_config['nsx']['nsx_username'],
    nsx_password        => $neutron_config['nsx']['nsx_password'],
    nsx_endpoint        => $neutron_config['nsx']['nsx_controllers'],
    transport_zone_uuid => $neutron_config['nsx']['transport_zone_uuid'],
    ip_address          => $ip_address,
    connector_type      => $neutron_config['nsx']['connector_type'],
    integration_bridge  => $integration_bridge,
  }

  if ! $on_compute {
    if ! defined(File['/etc/neutron']) {
      file { '/etc/neutron':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
      }
    }

    package { 'openstack-neutron-vmware':
      name => $::plugin_neutronnsx::params::neutron_plugin_package,
      ensure => present,
    } ->
    File['/etc/neutron'] ->
    file { '/etc/neutron/plugins/vmware':
      ensure  => directory,
      mode    => '0755',
    } ->
    File <| title == '/etc/neutron/plugin.ini' |> {
      ensure  => link,
      target  => '/etc/neutron/plugins/vmware/nsx.ini',
    } ->
    neutron_plugin_vmware {
      'DATABASE/sql_connection':      value => $neutron_config['database']['url'];
      'DATABASE/sql_max_retries':     value => $neutron_config['database']['reconnects'];
      'DATABASE/reconnect_interval':  value => $neutron_config['database']['reconnect_interval'];
      'DEFAULT/default_tz_uuid':            value => $neutron_config['nsx']['transport_zone_uuid'];
      'DEFAULT/nsx_user':                   value => $neutron_config['nsx']['nsx_username'];
      'DEFAULT/nsx_password':               value => $neutron_config['nsx']['nsx_password'];
      'DEFAULT/req_timeout':                value => 30;
      'DEFAULT/http_timeout':               value => 10;
      'DEFAULT/retries':                    value => 2;
      'DEFAULT/redirects':                  value => 2;
      'DEFAULT/nsx_controllers':            value => $neutron_config['nsx']['nsx_controllers'];
      'DEFAULT/default_l3_gw_service_uuid': value => $neutron_config['nsx']['l3_gw_service_uuid'];
      'quotas/quota_network_gateway':       value => -1;
      'nsx/max_lp_per_bridged_ls':          value => 5000;
      'nsx/max_lp_per_overlay_ls':          value => 256;
      'nsx/metadata_mode':                  value => 'dhcp_host_route';
      'nsx/default_transport_type':         value => $neutron_config['nsx']['connector_type'];
    }
  }
  anchor {'neutron-plugin-vmware-done':}
}
