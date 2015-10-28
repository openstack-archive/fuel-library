class { 'Cluster::Neutron::Metadata':
  name    => 'Cluster::Neutron::Metadata',
  primary => 'false',
  require => 'Class[Cluster::Neutron]',
}

class { 'Cluster::Neutron':
  name => 'Cluster::Neutron',
}

class { 'Neutron::Agents::Metadata':
  auth_insecure             => 'false',
  auth_password             => 'oT56DSZF',
  auth_region               => 'RegionOne',
  auth_tenant               => 'services',
  auth_url                  => 'http://192.168.0.2:35357/v2.0',
  auth_user                 => 'neutron',
  debug                     => 'false',
  enabled                   => 'true',
  manage_service            => 'true',
  metadata_backlog          => '4096',
  metadata_ip               => '192.168.0.2',
  metadata_memory_cache_ttl => '5',
  metadata_port             => '8775',
  metadata_protocol         => 'http',
  metadata_workers          => '4',
  name                      => 'Neutron::Agents::Metadata',
  package_ensure            => 'present',
  shared_secret             => 'fp618p5V',
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

cluster::corosync::cs_service { 'neutron-metadata-agent':
  csr_complex_type => 'clone',
  csr_mon_intr     => '60',
  csr_mon_timeout  => '10',
  csr_ms_metadata  => {'interleave' => 'true'},
  csr_timeout      => '30',
  hasrestart       => 'true',
  name             => 'neutron-metadata-agent',
  ocf_script       => 'ocf-neutron-metadata-agent',
  package_name     => 'neutron-metadata-agent',
  primary          => 'false',
  service_name     => 'neutron-metadata-agent',
  service_title    => 'neutron-metadata',
}

exec { 'remove_neutron-metadata-agent_override':
  before  => 'Service[neutron-metadata]',
  command => 'rm -f /etc/init/neutron-metadata-agent.override',
  onlyif  => 'test -f /etc/init/neutron-metadata-agent.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/var/cache/neutron':
  ensure => 'directory',
  group  => 'neutron',
  mode   => '0755',
  owner  => 'neutron',
  path   => '/var/cache/neutron',
}

file { 'create_neutron-metadata-agent_override':
  ensure  => 'present',
  before  => ['Package[neutron-metadata]', 'Exec[remove_neutron-metadata-agent_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/neutron-metadata-agent.override',
}

neutron_metadata_agent_config { 'DEFAULT/admin_password':
  name   => 'DEFAULT/admin_password',
  notify => 'Service[neutron-metadata]',
  secret => 'true',
  value  => 'oT56DSZF',
}

neutron_metadata_agent_config { 'DEFAULT/admin_tenant_name':
  name   => 'DEFAULT/admin_tenant_name',
  notify => 'Service[neutron-metadata]',
  value  => 'services',
}

neutron_metadata_agent_config { 'DEFAULT/admin_user':
  name   => 'DEFAULT/admin_user',
  notify => 'Service[neutron-metadata]',
  value  => 'neutron',
}

neutron_metadata_agent_config { 'DEFAULT/auth_ca_cert':
  ensure => 'absent',
  name   => 'DEFAULT/auth_ca_cert',
  notify => 'Service[neutron-metadata]',
}

neutron_metadata_agent_config { 'DEFAULT/auth_insecure':
  name   => 'DEFAULT/auth_insecure',
  notify => 'Service[neutron-metadata]',
  value  => 'false',
}

neutron_metadata_agent_config { 'DEFAULT/auth_region':
  name   => 'DEFAULT/auth_region',
  notify => 'Service[neutron-metadata]',
  value  => 'RegionOne',
}

neutron_metadata_agent_config { 'DEFAULT/auth_url':
  name   => 'DEFAULT/auth_url',
  notify => 'Service[neutron-metadata]',
  value  => 'http://192.168.0.2:35357/v2.0',
}

neutron_metadata_agent_config { 'DEFAULT/cache_url':
  name   => 'DEFAULT/cache_url',
  notify => 'Service[neutron-metadata]',
  value  => 'memory://?default_ttl=5',
}

neutron_metadata_agent_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => 'Service[neutron-metadata]',
  value  => 'false',
}

neutron_metadata_agent_config { 'DEFAULT/metadata_backlog':
  name   => 'DEFAULT/metadata_backlog',
  notify => 'Service[neutron-metadata]',
  value  => '4096',
}

neutron_metadata_agent_config { 'DEFAULT/metadata_proxy_shared_secret':
  name   => 'DEFAULT/metadata_proxy_shared_secret',
  notify => 'Service[neutron-metadata]',
  value  => 'fp618p5V',
}

neutron_metadata_agent_config { 'DEFAULT/metadata_workers':
  name   => 'DEFAULT/metadata_workers',
  notify => 'Service[neutron-metadata]',
  value  => '4',
}

neutron_metadata_agent_config { 'DEFAULT/nova_metadata_ip':
  name   => 'DEFAULT/nova_metadata_ip',
  notify => 'Service[neutron-metadata]',
  value  => '192.168.0.2',
}

neutron_metadata_agent_config { 'DEFAULT/nova_metadata_port':
  name   => 'DEFAULT/nova_metadata_port',
  notify => 'Service[neutron-metadata]',
  value  => '8775',
}

neutron_metadata_agent_config { 'DEFAULT/nova_metadata_protocol':
  name   => 'DEFAULT/nova_metadata_protocol',
  notify => 'Service[neutron-metadata]',
  value  => 'http',
}

package { 'lsof':
  name => 'lsof',
}

package { 'neutron-metadata':
  ensure  => 'present',
  before  => ['Service[neutron-metadata]', 'Exec[remove_neutron-metadata-agent_override]'],
  name    => 'neutron-metadata-agent',
  notify  => 'Service[neutron-metadata]',
  require => 'Package[neutron]',
  tag     => ['openstack', 'neutron-package'],
}

package { 'neutron':
  ensure => 'installed',
  before => 'File[/var/cache/neutron]',
  name   => 'binutils',
  notify => 'Service[neutron-metadata]',
}

service { 'neutron-metadata':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'neutron-metadata-agent',
  provider   => 'pacemaker',
  require    => 'Class[Neutron]',
  tag        => 'neutron-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'neutron-metadata-agent':
  before       => 'Service[neutron-metadata]',
  name         => 'neutron-metadata-agent',
  package_name => 'neutron-metadata-agent',
  service_name => 'neutron-metadata-agent',
}

