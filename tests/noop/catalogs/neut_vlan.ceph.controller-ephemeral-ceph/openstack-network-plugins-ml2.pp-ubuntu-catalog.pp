class { 'Cluster::Neutron::Ovs':
  name          => 'Cluster::Neutron::Ovs',
  plugin_config => '/etc/neutron/plugin.ini',
  primary       => 'true',
  require       => 'Class[Cluster::Neutron]',
}

class { 'Cluster::Neutron':
  name => 'Cluster::Neutron',
}

class { 'Neutron::Agents::Ml2::Ovs':
  arp_responder              => 'false',
  bridge_mappings            => 'physnet2:br-prv',
  bridge_uplinks             => [],
  drop_flows_on_start        => 'false',
  enable_distributed_routing => 'false',
  enable_tunneling           => 'false',
  enabled                    => 'true',
  firewall_driver            => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
  integration_bridge         => 'br-int',
  l2_population              => 'false',
  local_ip                   => 'false',
  manage_service             => 'true',
  manage_vswitch             => 'false',
  name                       => 'Neutron::Agents::Ml2::Ovs',
  package_ensure             => 'present',
  polling_interval           => '2',
  prevent_arp_spoofing       => 'true',
  tunnel_bridge              => 'br-tun',
  tunnel_types               => [],
  vxlan_udp_port             => '4789',
}

class { 'Neutron::Db::Sync':
  name => 'Neutron::Db::Sync',
}

class { 'Neutron::Params':
  name => 'Neutron::Params',
}

class { 'Neutron::Plugins::Ml2':
  enable_security_group     => 'true',
  flat_networks             => '*',
  mechanism_drivers         => ['openvswitch', 'l2population'],
  name                      => 'Neutron::Plugins::Ml2',
  network_vlan_ranges       => 'physnet2:1000:1030',
  package_ensure            => 'present',
  path_mtu                  => '1500',
  physical_network_mtus     => 'physnet2:1500',
  sriov_agent_required      => 'false',
  supported_pci_vendor_devs => ['15b3:1004', '8086:10ca'],
  tenant_network_types      => ['flat', 'vlan'],
  tunnel_id_ranges          => [],
  type_drivers              => ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  vni_ranges                => [],
  vxlan_group               => '224.0.0.1',
}

class { 'Neutron':
  name => 'Neutron',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cluster::corosync::cs_service { 'ovs':
  csr_complex_type => 'clone',
  csr_mon_intr     => '20',
  csr_mon_timeout  => '10',
  csr_ms_metadata  => {'interleave' => 'true'},
  csr_parameters   => {'plugin_config' => '/etc/neutron/plugin.ini'},
  csr_timeout      => '80',
  hasrestart       => 'false',
  name             => 'ovs',
  ocf_script       => 'ocf-neutron-ovs-agent',
  package_name     => 'neutron-plugin-openvswitch-agent',
  primary          => 'true',
  service_name     => 'neutron-plugin-openvswitch-agent',
  service_title    => 'neutron-ovs-agent-service',
}

cs_resource { 'p_neutron-plugin-openvswitch-agent':
  ensure          => 'present',
  before          => 'Service[neutron-ovs-agent-service]',
  complex_type    => 'clone',
  ms_metadata     => {'interleave' => 'true'},
  name            => 'p_neutron-plugin-openvswitch-agent',
  operations      => {'monitor' => {'interval' => '20', 'timeout' => '10'}, 'start' => {'timeout' => '80'}, 'stop' => {'timeout' => '80'}},
  parameters      => {'plugin_config' => '/etc/neutron/plugin.ini'},
  primitive_class => 'ocf',
  primitive_type  => 'ocf-neutron-ovs-agent',
  provided_by     => 'fuel',
}

exec { 'neutron-db-sync':
  command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
  logoutput   => 'on_failure',
  notify      => ['Service[neutron-ovs-agent-service]', 'Service[neutron-server]'],
  path        => '/usr/bin',
  refreshonly => 'true',
}

exec { 'remove_neutron-plugin-openvswitch-agent_override':
  before  => 'Service[neutron-ovs-agent-service]',
  command => 'rm -f /etc/init/neutron-plugin-openvswitch-agent.override',
  onlyif  => 'test -f /etc/init/neutron-plugin-openvswitch-agent.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'waiting-for-neutron-api':
  command     => 'neutron net-list --http-timeout=4 2>&1 > /dev/null',
  environment => ['OS_TENANT_NAME=services', 'OS_USERNAME=neutron', 'OS_PASSWORD=muG6m84W', 'OS_AUTH_URL=http://10.122.12.2:5000/v2.0', 'OS_REGION_NAME=RegionOne', 'OS_ENDPOINT_TYPE=internalURL'],
  path        => '/usr/sbin:/usr/bin:/sbin:/bin',
  provider    => 'shell',
  tries       => '30',
  try_sleep   => '4',
}

file { '/etc/default/neutron-server':
  ensure => 'present',
  group  => 'root',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/default/neutron-server',
}

file { '/etc/neutron/plugin.ini':
  ensure => 'link',
  path   => '/etc/neutron/plugin.ini',
  target => '/etc/neutron/plugins/ml2/ml2_conf.ini',
}

file { '/var/cache/neutron':
  ensure => 'directory',
  group  => 'neutron',
  mode   => '0755',
  owner  => 'neutron',
  path   => '/var/cache/neutron',
}

file { 'create_neutron-plugin-openvswitch-agent_override':
  ensure  => 'present',
  before  => ['Package[neutron-ovs-agent]', 'Exec[remove_neutron-plugin-openvswitch-agent_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/neutron-plugin-openvswitch-agent.override',
}

file_line { '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG':
  line    => 'NEUTRON_PLUGIN_CONFIG=/etc/neutron/plugin.ini',
  match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
  name    => '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG',
  notify  => 'Service[neutron-server]',
  path    => '/etc/default/neutron-server',
  require => ['File[/etc/default/neutron-server]', 'File[/etc/neutron/plugin.ini]'],
}

neutron::plugins::ml2::mech_driver { 'l2population':
  name                      => 'l2population',
  sriov_agent_required      => 'false',
  supported_pci_vendor_devs => ['15b3:1004', '8086:10ca'],
}

neutron::plugins::ml2::mech_driver { 'openvswitch':
  name                      => 'openvswitch',
  sriov_agent_required      => 'false',
  supported_pci_vendor_devs => ['15b3:1004', '8086:10ca'],
}

neutron::plugins::ml2::type_driver { 'flat':
  flat_networks       => '*',
  name                => 'flat',
  network_vlan_ranges => 'physnet2:1000:1030',
  tunnel_id_ranges    => [],
  vni_ranges          => [],
  vxlan_group         => '224.0.0.1',
}

neutron::plugins::ml2::type_driver { 'gre':
  flat_networks       => '*',
  name                => 'gre',
  network_vlan_ranges => 'physnet2:1000:1030',
  tunnel_id_ranges    => [],
  vni_ranges          => [],
  vxlan_group         => '224.0.0.1',
}

neutron::plugins::ml2::type_driver { 'local':
  flat_networks       => '*',
  name                => 'local',
  network_vlan_ranges => 'physnet2:1000:1030',
  tunnel_id_ranges    => [],
  vni_ranges          => [],
  vxlan_group         => '224.0.0.1',
}

neutron::plugins::ml2::type_driver { 'vlan':
  flat_networks       => '*',
  name                => 'vlan',
  network_vlan_ranges => 'physnet2:1000:1030',
  tunnel_id_ranges    => [],
  vni_ranges          => [],
  vxlan_group         => '224.0.0.1',
}

neutron::plugins::ml2::type_driver { 'vxlan':
  flat_networks       => '*',
  name                => 'vxlan',
  network_vlan_ranges => 'physnet2:1000:1030',
  tunnel_id_ranges    => [],
  vni_ranges          => [],
  vxlan_group         => '224.0.0.1',
}

neutron_agent_ovs { 'agent/arp_responder':
  name   => 'agent/arp_responder',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'false',
}

neutron_agent_ovs { 'agent/drop_flows_on_start':
  name   => 'agent/drop_flows_on_start',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'false',
}

neutron_agent_ovs { 'agent/enable_distributed_routing':
  name   => 'agent/enable_distributed_routing',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'false',
}

neutron_agent_ovs { 'agent/l2_population':
  name   => 'agent/l2_population',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'false',
}

neutron_agent_ovs { 'agent/polling_interval':
  name   => 'agent/polling_interval',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => '2',
}

neutron_agent_ovs { 'agent/prevent_arp_spoofing':
  name   => 'agent/prevent_arp_spoofing',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'true',
}

neutron_agent_ovs { 'ovs/bridge_mappings':
  name   => 'ovs/bridge_mappings',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'physnet2:br-prv',
}

neutron_agent_ovs { 'ovs/enable_tunneling':
  name   => 'ovs/enable_tunneling',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'false',
}

neutron_agent_ovs { 'ovs/integration_bridge':
  name   => 'ovs/integration_bridge',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'br-int',
}

neutron_agent_ovs { 'ovs/local_ip':
  ensure => 'absent',
  name   => 'ovs/local_ip',
  notify => 'Service[neutron-ovs-agent-service]',
}

neutron_agent_ovs { 'ovs/tunnel_bridge':
  ensure => 'absent',
  name   => 'ovs/tunnel_bridge',
  notify => 'Service[neutron-ovs-agent-service]',
}

neutron_agent_ovs { 'securitygroup/firewall_driver':
  name   => 'securitygroup/firewall_driver',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
}

neutron_plugin_ml2 { 'ml2/mechanism_drivers':
  name   => 'ml2/mechanism_drivers',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => 'openvswitch,l2population',
}

neutron_plugin_ml2 { 'ml2/path_mtu':
  name   => 'ml2/path_mtu',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => '1500',
}

neutron_plugin_ml2 { 'ml2/physical_network_mtus':
  name   => 'ml2/physical_network_mtus',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => 'physnet2:1500',
}

neutron_plugin_ml2 { 'ml2/tenant_network_types':
  name   => 'ml2/tenant_network_types',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => 'flat,vlan',
}

neutron_plugin_ml2 { 'ml2/type_drivers':
  name   => 'ml2/type_drivers',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => 'local,flat,vlan,gre,vxlan',
}

neutron_plugin_ml2 { 'ml2_type_flat/flat_networks':
  name   => 'ml2_type_flat/flat_networks',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => '*',
}

neutron_plugin_ml2 { 'ml2_type_gre/tunnel_id_ranges':
  name   => 'ml2_type_gre/tunnel_id_ranges',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => '',
}

neutron_plugin_ml2 { 'ml2_type_vlan/network_vlan_ranges':
  name   => 'ml2_type_vlan/network_vlan_ranges',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => 'physnet2:1000:1030',
}

neutron_plugin_ml2 { 'ml2_type_vxlan/vni_ranges':
  name   => 'ml2_type_vxlan/vni_ranges',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => '',
}

neutron_plugin_ml2 { 'ml2_type_vxlan/vxlan_group':
  name   => 'ml2_type_vxlan/vxlan_group',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => '224.0.0.1',
}

neutron_plugin_ml2 { 'securitygroup/enable_security_group':
  name   => 'securitygroup/enable_security_group',
  notify => ['Service[neutron-server]', 'Exec[neutron-db-sync]'],
  value  => 'true',
}

package { 'lsof':
  name => 'lsof',
}

package { 'neutron-ovs-agent':
  ensure => 'present',
  before => 'Exec[remove_neutron-plugin-openvswitch-agent_override]',
  name   => 'neutron-plugin-openvswitch-agent',
  notify => ['Service[neutron-ovs-agent-service]', 'Exec[neutron-db-sync]'],
  tag    => ['openstack', 'neutron-package'],
}

package { 'neutron-plugin-ml2':
  ensure => 'present',
  before => ['File[/etc/neutron/plugin.ini]', 'File[/etc/default/neutron-server]'],
  name   => 'neutron-plugin-ml2',
  tag    => 'openstack',
}

package { 'neutron':
  ensure => 'installed',
  before => 'File[/var/cache/neutron]',
  name   => 'binutils',
  notify => 'Service[neutron-ovs-agent-service]',
}

service { 'neutron-ovs-agent-service':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'false',
  hasstatus  => 'true',
  name       => 'neutron-plugin-openvswitch-agent',
  provider   => 'pacemaker',
  require    => 'Class[Neutron]',
  tag        => 'neutron-service',
}

service { 'neutron-server':
  ensure     => 'running',
  before     => 'Exec[waiting-for-neutron-api]',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'neutron-server',
  tag        => 'neutron-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'neutron-plugin-openvswitch-agent':
  before       => 'Service[neutron-ovs-agent-service]',
  name         => 'neutron-plugin-openvswitch-agent',
  package_name => 'neutron-plugin-openvswitch-agent',
  service_name => 'neutron-plugin-openvswitch-agent',
}

