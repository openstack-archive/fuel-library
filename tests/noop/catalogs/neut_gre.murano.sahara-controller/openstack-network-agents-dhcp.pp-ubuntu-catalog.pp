class { 'Cluster::Neutron::Dhcp':
  agents_per_net => '2',
  ha_agents      => ['ovs', 'metadata', 'dhcp', 'l3'],
  name           => 'Cluster::Neutron::Dhcp',
  plugin_config  => '/etc/neutron/dhcp_agent.ini',
  primary        => 'false',
  require        => 'Class[Cluster::Neutron]',
}

class { 'Cluster::Neutron':
  name => 'Cluster::Neutron',
}

class { 'Neutron::Agents::Dhcp':
  debug                    => 'false',
  dhcp_broadcast_reply     => 'false',
  dhcp_delete_namespaces   => 'true',
  dhcp_domain              => 'openstacklocal',
  dhcp_driver              => 'neutron.agent.linux.dhcp.Dnsmasq',
  enable_isolated_metadata => 'true',
  enable_metadata_network  => 'false',
  enabled                  => 'true',
  interface_driver         => 'neutron.agent.linux.interface.OVSInterfaceDriver',
  manage_service           => 'true',
  name                     => 'Neutron::Agents::Dhcp',
  package_ensure           => 'present',
  resync_interval          => '30',
  root_helper              => 'sudo neutron-rootwrap /etc/neutron/rootwrap.conf',
  state_path               => '/var/lib/neutron',
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

cluster::corosync::cs_service { 'dhcp':
  csr_complex_type => 'clone',
  csr_mon_intr     => '20',
  csr_mon_timeout  => '10',
  csr_ms_metadata  => {'interleave' => 'true'},
  csr_parameters   => {'plugin_config' => '/etc/neutron/dhcp_agent.ini', 'remove_artifacts_on_stop_start' => 'true'},
  csr_timeout      => '60',
  hasrestart       => 'false',
  name             => 'dhcp',
  ocf_script       => 'ocf-neutron-dhcp-agent',
  package_name     => 'neutron-dhcp-agent',
  primary          => 'false',
  service_name     => 'neutron-dhcp-agent',
  service_title    => 'neutron-dhcp-service',
}

exec { 'remove_neutron-dhcp-agent_override':
  before  => 'Service[neutron-dhcp-service]',
  command => 'rm -f /etc/init/neutron-dhcp-agent.override',
  onlyif  => 'test -f /etc/init/neutron-dhcp-agent.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/var/cache/neutron':
  ensure => 'directory',
  group  => 'neutron',
  mode   => '0755',
  owner  => 'neutron',
  path   => '/var/cache/neutron',
}

file { 'create_neutron-dhcp-agent_override':
  ensure  => 'present',
  before  => ['Package[neutron-dhcp-agent]', 'Package[neutron-dhcp-agent]', 'Exec[remove_neutron-dhcp-agent_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/neutron-dhcp-agent.override',
}

neutron_dhcp_agent_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => 'Service[neutron-dhcp-service]',
  value  => 'false',
}

neutron_dhcp_agent_config { 'DEFAULT/dhcp_broadcast_reply':
  name   => 'DEFAULT/dhcp_broadcast_reply',
  notify => 'Service[neutron-dhcp-service]',
  value  => 'false',
}

neutron_dhcp_agent_config { 'DEFAULT/dhcp_delete_namespaces':
  name   => 'DEFAULT/dhcp_delete_namespaces',
  notify => 'Service[neutron-dhcp-service]',
  value  => 'true',
}

neutron_dhcp_agent_config { 'DEFAULT/dhcp_domain':
  name   => 'DEFAULT/dhcp_domain',
  notify => 'Service[neutron-dhcp-service]',
  value  => 'openstacklocal',
}

neutron_dhcp_agent_config { 'DEFAULT/dhcp_driver':
  name   => 'DEFAULT/dhcp_driver',
  notify => 'Service[neutron-dhcp-service]',
  value  => 'neutron.agent.linux.dhcp.Dnsmasq',
}

neutron_dhcp_agent_config { 'DEFAULT/dnsmasq_config_file':
  ensure => 'absent',
  name   => 'DEFAULT/dnsmasq_config_file',
  notify => 'Service[neutron-dhcp-service]',
}

neutron_dhcp_agent_config { 'DEFAULT/enable_isolated_metadata':
  name   => 'DEFAULT/enable_isolated_metadata',
  notify => 'Service[neutron-dhcp-service]',
  value  => 'true',
}

neutron_dhcp_agent_config { 'DEFAULT/enable_metadata_network':
  name   => 'DEFAULT/enable_metadata_network',
  notify => 'Service[neutron-dhcp-service]',
  value  => 'false',
}

neutron_dhcp_agent_config { 'DEFAULT/interface_driver':
  name   => 'DEFAULT/interface_driver',
  notify => 'Service[neutron-dhcp-service]',
  value  => 'neutron.agent.linux.interface.OVSInterfaceDriver',
}

neutron_dhcp_agent_config { 'DEFAULT/resync_interval':
  name   => 'DEFAULT/resync_interval',
  notify => 'Service[neutron-dhcp-service]',
  value  => '30',
}

neutron_dhcp_agent_config { 'DEFAULT/root_helper':
  name   => 'DEFAULT/root_helper',
  notify => 'Service[neutron-dhcp-service]',
  value  => 'sudo neutron-rootwrap /etc/neutron/rootwrap.conf',
}

neutron_dhcp_agent_config { 'DEFAULT/state_path':
  name   => 'DEFAULT/state_path',
  notify => 'Service[neutron-dhcp-service]',
  value  => '/var/lib/neutron',
}

package { 'dnsmasq-base':
  ensure => 'present',
  before => 'Package[neutron-dhcp-agent]',
  name   => 'dnsmasq-base',
}

package { 'dnsmasq-utils':
  ensure => 'present',
  before => 'Package[neutron-dhcp-agent]',
  name   => 'dnsmasq-utils',
}

package { 'lsof':
  name => 'lsof',
}

package { 'neutron-dhcp-agent':
  ensure => 'present',
  before => ['Neutron_dhcp_agent_config[DEFAULT/enable_isolated_metadata]', 'Neutron_dhcp_agent_config[DEFAULT/enable_metadata_network]', 'Neutron_dhcp_agent_config[DEFAULT/debug]', 'Neutron_dhcp_agent_config[DEFAULT/state_path]', 'Neutron_dhcp_agent_config[DEFAULT/resync_interval]', 'Neutron_dhcp_agent_config[DEFAULT/interface_driver]', 'Neutron_dhcp_agent_config[DEFAULT/dhcp_domain]', 'Neutron_dhcp_agent_config[DEFAULT/dhcp_driver]', 'Neutron_dhcp_agent_config[DEFAULT/root_helper]', 'Neutron_dhcp_agent_config[DEFAULT/dhcp_delete_namespaces]', 'Neutron_dhcp_agent_config[DEFAULT/dhcp_broadcast_reply]', 'Neutron_dhcp_agent_config[DEFAULT/dnsmasq_config_file]', 'Exec[remove_neutron-dhcp-agent_override]', 'Exec[remove_neutron-dhcp-agent_override]'],
  name   => 'neutron-dhcp-agent',
  notify => 'Service[neutron-dhcp-service]',
  tag    => ['openstack', 'neutron-package'],
}

package { 'neutron':
  ensure => 'installed',
  before => ['Package[neutron-dhcp-agent]', 'File[/var/cache/neutron]'],
  name   => 'binutils',
  notify => 'Service[neutron-dhcp-service]',
}

service { 'neutron-dhcp-service':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'false',
  hasstatus  => 'true',
  name       => 'neutron-dhcp-agent',
  provider   => 'pacemaker',
  require    => 'Class[Neutron]',
  tag        => 'neutron-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'neutron-dhcp-agent':
  before       => 'Service[neutron-dhcp-service]',
  name         => 'neutron-dhcp-agent',
  package_name => 'neutron-dhcp-agent',
  service_name => 'neutron-dhcp-agent',
}

