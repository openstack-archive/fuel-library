class plugin_neutronnsx::alter_neutron_server (
  $neutron_config,
  $neutron_nsx_config,
)
{
  include plugin_neutronnsx::params

  # anchor {'alter-neutron-server-vmware-start':}
  # anchor {'alter-neutron-server-vmware-end':}

  # Anchor<| title=='neutron-server-config-done' |> ->
  #   Anchor['alter-neutron-server-vmware-start']

  # Anchor['alter-neutron-server-vmware-end'] ->
  #   Anchor<| title=='neutron-server-done' |>

  if $::osfamily =~ /(?i)debian/ {
    exec { 'enable_plugin':
      command => "/bin/sed -i 's/^NEUTRON_PLUGIN_CONFIG.*/NEUTRON_PLUGIN_CONFIG=\/etc\/neutron\/plugin.ini/g' /etc/default/neutron-server",
    }
    Package<| title == $::neutron::params::server_package |> -> Exec['enable_plugin'] ~> Service<| title == 'neutron-server' |>
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

  Neutron_plugin_vmware<||> ~> Service<| title == 'neutron-server' |>
  
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
    'DEFAULT/default_tz_uuid':            value => $neutron_nsx_config['transport_zone_uuid'];
    'DEFAULT/nsx_user':                   value => $neutron_nsx_config['nsx_username'];
    'DEFAULT/nsx_password':               value => $neutron_nsx_config['nsx_password'];
    'DEFAULT/req_timeout':                value => 30;
    'DEFAULT/http_timeout':               value => 10;
    'DEFAULT/retries':                    value => 2;
    'DEFAULT/redirects':                  value => 2;
    'DEFAULT/nsx_controllers':            value => $neutron_nsx_config['nsx_controllers'];
    'DEFAULT/default_l3_gw_service_uuid': value => $neutron_nsx_config['l3_gw_service_uuid'];
    'quotas/quota_network_gateway':       value => -1;
    'nsx/max_lp_per_bridged_ls':          value => 5000;
    'nsx/max_lp_per_overlay_ls':          value => 256;
    'nsx/metadata_mode':                  value => 'dhcp_host_route';
    'nsx/default_transport_type':         value => $neutron_nsx_config['connector_type'];
  }
