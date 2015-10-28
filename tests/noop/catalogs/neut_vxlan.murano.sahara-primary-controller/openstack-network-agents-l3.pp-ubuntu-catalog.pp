class { 'Cluster::Neutron':
  name => 'Cluster::Neutron',
}

class { 'Neutron::Agents::L3':
  agent_mode                       => 'dvr-snat',
  allow_automatic_l3agent_failover => 'false',
  debug                            => 'false',
  enable_metadata_proxy            => 'true',
  enabled                          => 'true',
  external_network_bridge          => 'br-floating',
  ha_enabled                       => 'false',
  ha_vrrp_advert_int               => '3',
  ha_vrrp_auth_type                => 'PASS',
  handle_internal_only_routers     => 'true',
  interface_driver                 => 'neutron.agent.linux.interface.OVSInterfaceDriver',
  manage_service                   => 'true',
  metadata_port                    => '8775',
  name                             => 'Neutron::Agents::L3',
  package_ensure                   => 'present',
  periodic_fuzzy_delay             => '5',
  periodic_interval                => '40',
  router_delete_namespaces         => 'true',
  send_arp_for_ha                  => '3',
}

class { 'Neutron::Params':
  name => 'Neutron::Params',
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

cluster::corosync::cs_service { 'l3':
  csr_complex_type => 'clone',
  csr_mon_intr     => '20',
  csr_mon_timeout  => '10',
  csr_ms_metadata  => {'interleave' => 'true'},
  csr_parameters   => {'plugin_config' => '/etc/neutron/l3_agent.ini', 'remove_artifacts_on_stop_start' => 'true'},
  csr_timeout      => '60',
  hasrestart       => 'false',
  name             => 'l3',
  ocf_script       => 'ocf-neutron-l3-agent',
  package_name     => 'neutron-l3-agent',
  primary          => 'true',
  service_name     => 'neutron-l3-agent',
  service_title    => 'neutron-l3',
}

cluster::neutron::l3 { 'default-l3':
  ha_agents     => ['ovs', 'metadata', 'dhcp', 'l3'],
  name          => 'default-l3',
  plugin_config => '/etc/neutron/l3_agent.ini',
  primary       => 'true',
  require       => 'Class[Cluster::Neutron]',
}

cs_resource { 'p_neutron-l3-agent':
  ensure          => 'present',
  before          => 'Service[neutron-l3]',
  complex_type    => 'clone',
  ms_metadata     => {'interleave' => 'true'},
  name            => 'p_neutron-l3-agent',
  operations      => {'monitor' => {'interval' => '20', 'timeout' => '10'}, 'start' => {'timeout' => '60'}, 'stop' => {'timeout' => '60'}},
  parameters      => {'plugin_config' => '/etc/neutron/l3_agent.ini', 'remove_artifacts_on_stop_start' => 'true'},
  primitive_class => 'ocf',
  primitive_type  => 'ocf-neutron-l3-agent',
  provided_by     => 'fuel',
}

exec { 'remove_neutron-l3-agent_override':
  before  => 'Service[neutron-l3]',
  command => 'rm -f /etc/init/neutron-l3-agent.override',
  onlyif  => 'test -f /etc/init/neutron-l3-agent.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/var/cache/neutron':
  ensure => 'directory',
  group  => 'neutron',
  mode   => '0755',
  owner  => 'neutron',
  path   => '/var/cache/neutron',
}

file { 'create_neutron-l3-agent_override':
  ensure  => 'present',
  before  => ['Package[neutron-l3]', 'Exec[remove_neutron-l3-agent_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/neutron-l3-agent.override',
}

neutron_l3_agent_config { 'DEFAULT/agent_mode':
  name   => 'DEFAULT/agent_mode',
  notify => 'Service[neutron-l3]',
  value  => 'dvr-snat',
}

neutron_l3_agent_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => 'Service[neutron-l3]',
  value  => 'false',
}

neutron_l3_agent_config { 'DEFAULT/enable_metadata_proxy':
  name   => 'DEFAULT/enable_metadata_proxy',
  notify => 'Service[neutron-l3]',
  value  => 'true',
}

neutron_l3_agent_config { 'DEFAULT/external_network_bridge':
  name   => 'DEFAULT/external_network_bridge',
  notify => 'Service[neutron-l3]',
  value  => 'br-floating',
}

neutron_l3_agent_config { 'DEFAULT/gateway_external_network_id':
  name   => 'DEFAULT/gateway_external_network_id',
  notify => 'Service[neutron-l3]',
}

neutron_l3_agent_config { 'DEFAULT/handle_internal_only_routers':
  name   => 'DEFAULT/handle_internal_only_routers',
  notify => 'Service[neutron-l3]',
  value  => 'true',
}

neutron_l3_agent_config { 'DEFAULT/interface_driver':
  name   => 'DEFAULT/interface_driver',
  notify => 'Service[neutron-l3]',
  value  => 'neutron.agent.linux.interface.OVSInterfaceDriver',
}

neutron_l3_agent_config { 'DEFAULT/metadata_port':
  name   => 'DEFAULT/metadata_port',
  notify => 'Service[neutron-l3]',
  value  => '8775',
}

neutron_l3_agent_config { 'DEFAULT/network_device_mtu':
  ensure => 'absent',
  name   => 'DEFAULT/network_device_mtu',
  notify => 'Service[neutron-l3]',
}

neutron_l3_agent_config { 'DEFAULT/periodic_fuzzy_delay':
  name   => 'DEFAULT/periodic_fuzzy_delay',
  notify => 'Service[neutron-l3]',
  value  => '5',
}

neutron_l3_agent_config { 'DEFAULT/periodic_interval':
  name   => 'DEFAULT/periodic_interval',
  notify => 'Service[neutron-l3]',
  value  => '40',
}

neutron_l3_agent_config { 'DEFAULT/router_delete_namespaces':
  name   => 'DEFAULT/router_delete_namespaces',
  notify => 'Service[neutron-l3]',
  value  => 'true',
}

neutron_l3_agent_config { 'DEFAULT/router_id':
  name   => 'DEFAULT/router_id',
  notify => 'Service[neutron-l3]',
}

neutron_l3_agent_config { 'DEFAULT/send_arp_for_ha':
  name   => 'DEFAULT/send_arp_for_ha',
  notify => 'Service[neutron-l3]',
  value  => '3',
}

package { 'lsof':
  name => 'lsof',
}

package { 'neutron-l3':
  ensure  => 'present',
  before  => ['Neutron_l3_agent_config[DEFAULT/debug]', 'Neutron_l3_agent_config[DEFAULT/external_network_bridge]', 'Neutron_l3_agent_config[DEFAULT/interface_driver]', 'Neutron_l3_agent_config[DEFAULT/router_id]', 'Neutron_l3_agent_config[DEFAULT/gateway_external_network_id]', 'Neutron_l3_agent_config[DEFAULT/handle_internal_only_routers]', 'Neutron_l3_agent_config[DEFAULT/metadata_port]', 'Neutron_l3_agent_config[DEFAULT/send_arp_for_ha]', 'Neutron_l3_agent_config[DEFAULT/periodic_interval]', 'Neutron_l3_agent_config[DEFAULT/periodic_fuzzy_delay]', 'Neutron_l3_agent_config[DEFAULT/enable_metadata_proxy]', 'Neutron_l3_agent_config[DEFAULT/router_delete_namespaces]', 'Neutron_l3_agent_config[DEFAULT/agent_mode]', 'Neutron_l3_agent_config[DEFAULT/network_device_mtu]', 'Exec[remove_neutron-l3-agent_override]'],
  name    => 'neutron-l3-agent',
  notify  => 'Service[neutron-l3]',
  require => 'Package[neutron]',
  tag     => ['openstack', 'neutron-package'],
}

package { 'neutron':
  ensure => 'installed',
  before => 'File[/var/cache/neutron]',
  name   => 'binutils',
  notify => 'Service[neutron-l3]',
}

service { 'neutron-l3':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'false',
  hasstatus  => 'true',
  name       => 'neutron-l3-agent',
  provider   => 'pacemaker',
  require    => 'Class[Neutron]',
  tag        => 'neutron-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'neutron-l3-agent':
  before       => 'Service[neutron-l3]',
  name         => 'neutron-l3-agent',
  package_name => 'neutron-l3-agent',
  service_name => 'neutron-l3-agent',
}

