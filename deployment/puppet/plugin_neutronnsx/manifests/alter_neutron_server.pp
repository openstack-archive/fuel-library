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

  Neutron_network <| title == 'net04' |> {
    router_external => false,
    provider_network_type => undef,
    provider_physical_network => false,
    provider_segmentation_id => undef,
  }

  Neutron_network <| title == 'net04_ext' |> {
    router_external => true,
    provider_network_type => 'l3_ext',
    provider_physical_network => $neutron_nsx_config['l3_gw_service_uuid'],
    provider_segmentation_id => undef,
  }

  Neutron_subnet <| title == 'net04__subnet' |> {
    gateway_ip => false,
  }

  if $::osfamily =~ /(?i)debian/ {
    exec { 'enable_plugin':
      command => '/bin/sed -i \'s/^NEUTRON_PLUGIN_CONFIG.*/NEUTRON_PLUGIN_CONFIG=\/etc\/neutron\/plugin.ini/g\' /etc/default/neutron-server',
    }
    Package<| title == $::neutron::params::server_package |> -> Exec['enable_plugin'] ~> Service<| title == 'neutron-server' |>
  }

##########

  package { 'openstack-neutron-vmware':
    name   => $::plugin_neutronnsx::params::neutron_plugin_package,
    ensure => present,
  }

  package { 'openstack-neutron-ml2':
    name   => $::plugin_neutronnsx::params::ml2_server_package,
    ensure => present,
  }

  file { '/etc/neutron/plugins/vmware':
    ensure => directory,
    mode   => '0755',
  }

  if ! defined(File['/etc/neutron/plugins']) {
    file {'/etc/neutron/plugins':
      ensure => directory,
      mode   => '0755',
    } -> File <| title == '/etc/neutron/plugins/vmware' |>
  }

  if ! defined(File['/etc/neutron/plugin.ini']){
    file {'/etc/neutron/plugin.ini':
      ensure => link,
      target => '/etc/neutron/plugins/vmware/nsx.ini',
    }
  } else {
      File <| title == '/etc/neutron/plugin.ini' |> {
        ensure => link,
        target => '/etc/neutron/plugins/vmware/nsx.ini',
      }
  }

  Neutron_config <| title == 'DEFAULT/service_plugins' |> {
    ensure => absent,
  }

  Neutron_dhcp_agent_config<| title == 'DEFAULT/enable_isolated_metadata' or title == 'DEFAULT/enabl
e_metadata_network'|>{
    value => true,
  }

  # NSX cluster can operate without Service nodes.
  # If cluster lacks Service node we must configure `replication_mode'
  # configuration stanza with 'source' value.  It is usefull only for testing
  # purposes, production clusters must run with Service nodes.
  if $neutron_nsx_config['replication_mode'] {
    $replication_mode = 'service'
  } else {
    $replication_mode = 'source'
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
    'nsx/replication_mode':               value => $replication_mode;
  }

  Anchor['alter-neutron-server-vmware-start'] ->
  Package['openstack-neutron-vmware'] ->
  Neutron_plugin_vmware<||> ~>
  Service<| title == 'neutron-server' |> ->
  Anchor['alter-neutron-server-vmware-end']

  Package['openstack-neutron-ml2'] ->
  Package['openstack-neutron-vmware']

  Neutron_plugin_vmware<||> ~>
  Exec <| title == 'neutron-db-sync' |>

}
