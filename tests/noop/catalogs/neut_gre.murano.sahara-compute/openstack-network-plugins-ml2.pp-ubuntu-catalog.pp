class { 'Neutron::Agents::Ml2::Ovs':
  arp_responder              => 'true',
  bridge_mappings            => [],
  bridge_uplinks             => [],
  drop_flows_on_start        => 'false',
  enable_distributed_routing => 'true',
  enable_tunneling           => 'true',
  enabled                    => 'true',
  firewall_driver            => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
  integration_bridge         => 'br-int',
  l2_population              => 'true',
  local_ip                   => '192.168.0.5',
  manage_service             => 'true',
  manage_vswitch             => 'false',
  name                       => 'Neutron::Agents::Ml2::Ovs',
  package_ensure             => 'present',
  polling_interval           => '2',
  prevent_arp_spoofing       => 'true',
  tunnel_bridge              => 'br-tun',
  tunnel_types               => 'vxlan',
  vxlan_udp_port             => '4789',
}

class { 'Neutron::Params':
  name => 'Neutron::Params',
}

class { 'Neutron::Plugins::Ml2':
  enable_security_group     => 'true',
  flat_networks             => '*',
  mechanism_drivers         => ['openvswitch', 'l2population'],
  name                      => 'Neutron::Plugins::Ml2',
  network_vlan_ranges       => [],
  package_ensure            => 'present',
  path_mtu                  => '1450',
  physical_network_mtus     => [],
  sriov_agent_required      => 'false',
  supported_pci_vendor_devs => ['15b3:1004', '8086:10ca'],
  tenant_network_types      => ['flat', 'vxlan'],
  tunnel_id_ranges          => '2:65535',
  type_drivers              => ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  vni_ranges                => '2:65535',
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

file_line { '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG':
  line    => 'NEUTRON_PLUGIN_CONFIG=/etc/neutron/plugin.ini',
  match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
  name    => '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG',
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
  network_vlan_ranges => [],
  tunnel_id_ranges    => '2:65535',
  vni_ranges          => '2:65535',
  vxlan_group         => '224.0.0.1',
}

neutron::plugins::ml2::type_driver { 'gre':
  flat_networks       => '*',
  name                => 'gre',
  network_vlan_ranges => [],
  tunnel_id_ranges    => '2:65535',
  vni_ranges          => '2:65535',
  vxlan_group         => '224.0.0.1',
}

neutron::plugins::ml2::type_driver { 'local':
  flat_networks       => '*',
  name                => 'local',
  network_vlan_ranges => [],
  tunnel_id_ranges    => '2:65535',
  vni_ranges          => '2:65535',
  vxlan_group         => '224.0.0.1',
}

neutron::plugins::ml2::type_driver { 'vlan':
  flat_networks       => '*',
  name                => 'vlan',
  network_vlan_ranges => [],
  tunnel_id_ranges    => '2:65535',
  vni_ranges          => '2:65535',
  vxlan_group         => '224.0.0.1',
}

neutron::plugins::ml2::type_driver { 'vxlan':
  flat_networks       => '*',
  name                => 'vxlan',
  network_vlan_ranges => [],
  tunnel_id_ranges    => '2:65535',
  vni_ranges          => '2:65535',
  vxlan_group         => '224.0.0.1',
}

neutron_agent_ovs { 'agent/arp_responder':
  name   => 'agent/arp_responder',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'true',
}

neutron_agent_ovs { 'agent/drop_flows_on_start':
  name   => 'agent/drop_flows_on_start',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'false',
}

neutron_agent_ovs { 'agent/enable_distributed_routing':
  name   => 'agent/enable_distributed_routing',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'true',
}

neutron_agent_ovs { 'agent/l2_population':
  name   => 'agent/l2_population',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'true',
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

neutron_agent_ovs { 'agent/tunnel_types':
  name   => 'agent/tunnel_types',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'vxlan',
}

neutron_agent_ovs { 'agent/vxlan_udp_port':
  name   => 'agent/vxlan_udp_port',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => '4789',
}

neutron_agent_ovs { 'ovs/enable_tunneling':
  name   => 'ovs/enable_tunneling',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'true',
}

neutron_agent_ovs { 'ovs/integration_bridge':
  name   => 'ovs/integration_bridge',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'br-int',
}

neutron_agent_ovs { 'ovs/local_ip':
  name   => 'ovs/local_ip',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => '192.168.0.5',
}

neutron_agent_ovs { 'ovs/tunnel_bridge':
  name   => 'ovs/tunnel_bridge',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'br-tun',
}

neutron_agent_ovs { 'securitygroup/firewall_driver':
  name   => 'securitygroup/firewall_driver',
  notify => 'Service[neutron-ovs-agent-service]',
  value  => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
}

neutron_plugin_ml2 { 'ml2/mechanism_drivers':
  name  => 'ml2/mechanism_drivers',
  value => 'openvswitch,l2population',
}

neutron_plugin_ml2 { 'ml2/path_mtu':
  name  => 'ml2/path_mtu',
  value => '1450',
}

neutron_plugin_ml2 { 'ml2/physical_network_mtus':
  ensure => 'absent',
  name   => 'ml2/physical_network_mtus',
}

neutron_plugin_ml2 { 'ml2/tenant_network_types':
  name  => 'ml2/tenant_network_types',
  value => 'flat,vxlan',
}

neutron_plugin_ml2 { 'ml2/type_drivers':
  name  => 'ml2/type_drivers',
  value => 'local,flat,vlan,gre,vxlan',
}

neutron_plugin_ml2 { 'ml2_type_flat/flat_networks':
  name  => 'ml2_type_flat/flat_networks',
  value => '*',
}

neutron_plugin_ml2 { 'ml2_type_gre/tunnel_id_ranges':
  name  => 'ml2_type_gre/tunnel_id_ranges',
  value => '2:65535',
}

neutron_plugin_ml2 { 'ml2_type_vlan/network_vlan_ranges':
  name  => 'ml2_type_vlan/network_vlan_ranges',
  value => '',
}

neutron_plugin_ml2 { 'ml2_type_vxlan/vni_ranges':
  name  => 'ml2_type_vxlan/vni_ranges',
  value => '2:65535',
}

neutron_plugin_ml2 { 'ml2_type_vxlan/vxlan_group':
  name  => 'ml2_type_vxlan/vxlan_group',
  value => '224.0.0.1',
}

neutron_plugin_ml2 { 'securitygroup/enable_security_group':
  name  => 'securitygroup/enable_security_group',
  value => 'true',
}

package { 'neutron-ovs-agent':
  ensure => 'present',
  name   => 'neutron-plugin-openvswitch-agent',
  notify => 'Service[neutron-ovs-agent-service]',
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
  name   => 'binutils',
  notify => 'Service[neutron-ovs-agent-service]',
}

service { 'neutron-ovs-agent-service':
  ensure  => 'running',
  enable  => 'true',
  name    => 'neutron-plugin-openvswitch-agent',
  require => 'Class[Neutron]',
  tag     => 'neutron-service',
}

stage { 'main':
  name => 'main',
}

