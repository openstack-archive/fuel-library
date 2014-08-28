class plugin_neutronnsx::alter_neutron_server (
  $neutron_config,
  $neutron_nsx_config,
) {
  include plugin_neutronnsx::params

  anchor {'alter-neutron-server-vmware-start':}
  anchor {'alter-neutron-server-vmware-end':}

  Anchor<| title=='neutron-server-config-done' |> ->
  Anchor['alter-neutron-server-vmware-start']

  Anchor['alter-neutron-server-vmware-end'] ->
  Anchor<| title=='neutron-server-done' |>

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

  if $::osfamily =~ /(?i)debian/ {
    exec { 'enable_plugin':
      command => '/bin/sed -i \'s/^NEUTRON_PLUGIN_CONFIG.*/NEUTRON_PLUGIN_CONFIG=\/etc\/neutron\/plugin.ini/g\' /etc/default/neutron-server',
    }
    Package<| title == $::neutron::params::server_package |> -> Exec['enable_plugin'] ~> Service<| title == 'neutron-server' |>
  }

##########

  package { 'openstack-neutron-vmware':
    name => $::plugin_neutronnsx::params::neutron_plugin_package,
    ensure => present,
  }

  file { '/etc/neutron/plugins/vmware':
    ensure  => directory,
    mode    => '0755',
  }

  if ! defined(File['/etc/neutron/plugins']) {
    file {'/etc/neutron/plugins':
      ensure  => directory,
      mode    => '0755',
    } -> File <| title == '/etc/neutron/plugins/vmware' |>
  }

  File <| title == '/etc/neutron/plugin.ini' |> {
    ensure  => link,
    target  => '/etc/neutron/plugins/vmware/nsx.ini',
  }

  Neutron_config <| title == 'DEFAULT/service_plugins' |> {
    ensure => absent,
  }

  neutron_plugin_vmware {
    'DATABASE/sql_connection':            value => $neutron_config['database']['url'];
    'DATABASE/sql_max_retries':           value => $neutron_config['database']['reconnects'];
    'DATABASE/reconnect_interval':        value => $neutron_config['database']['reconnect_interval'];
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

  Anchor['alter-neutron-server-vmware-start'] ->
  Package['openstack-neutron-vmware'] ->
  Neutron_plugin_vmware<||> ~>
  Service<| title == 'neutron-server' |> ->
  Anchor['alter-neutron-server-vmware-end']

}
