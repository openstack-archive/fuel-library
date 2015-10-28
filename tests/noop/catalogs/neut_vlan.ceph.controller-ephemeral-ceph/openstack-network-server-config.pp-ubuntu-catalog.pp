class { 'Keystone::Params':
  name => 'Keystone::Params',
}

class { 'Keystone::Python':
  ensure              => 'present',
  client_package_name => 'python-keystone',
  name                => 'Keystone::Python',
}

class { 'Mysql::Bindings::Python':
  name => 'Mysql::Bindings::Python',
}

class { 'Mysql::Bindings':
  name => 'Mysql::Bindings',
}

class { 'Mysql::Params':
  name => 'Mysql::Params',
}

class { 'Mysql::Python':
  name           => 'Mysql::Python',
  package_ensure => 'present',
  package_name   => 'python-mysqldb',
}

class { 'Neutron::Db':
  database_connection     => 'sqlite:////var/lib/neutron/ovs.sqlite',
  database_idle_timeout   => '3600',
  database_max_overflow   => '20',
  database_max_pool_size  => '10',
  database_max_retries    => '10',
  database_min_pool_size  => '1',
  database_retry_interval => '10',
  name                    => 'Neutron::Db',
  require                 => ['Class[Mysql::Bindings]', 'Class[Mysql::Bindings::Python]'],
}

class { 'Neutron::Params':
  name => 'Neutron::Params',
}

class { 'Neutron::Policy':
  name        => 'Neutron::Policy',
  notify      => 'Service[neutron-server]',
  policies    => {},
  policy_path => '/etc/neutron/policy.json',
}

class { 'Neutron::Server::Notifications':
  name                               => 'Neutron::Server::Notifications',
  notify_nova_on_port_data_changes   => 'true',
  notify_nova_on_port_status_changes => 'true',
  nova_admin_auth_url                => 'http://10.122.12.2:35357/v2.0/',
  nova_admin_password                => 'vhdwzqrw',
  nova_admin_tenant_name             => 'services',
  nova_admin_username                => 'nova',
  nova_region_name                   => 'RegionOne',
  nova_url                           => 'http://10.122.12.2:8774/v2',
  send_events_interval               => '2',
}

class { 'Neutron::Server':
  agent_down_time                  => '30',
  allow_automatic_l3agent_failover => 'true',
  api_workers                      => '4',
  auth_admin_prefix                => 'false',
  auth_host                        => 'localhost',
  auth_password                    => 'muG6m84W',
  auth_port                        => '35357',
  auth_protocol                    => 'http',
  auth_region                      => 'RegionOne',
  auth_tenant                      => 'services',
  auth_type                        => 'keystone',
  auth_uri                         => 'http://10.122.12.2:5000/',
  auth_user                        => 'neutron',
  database_connection              => 'mysql://neutron:DVHUmPBa@10.122.12.2/neutron?&read_timeout=60',
  database_max_retries             => '-1',
  database_retry_interval          => '2',
  enabled                          => 'false',
  identity_uri                     => 'http://10.122.12.2:5000/',
  l3_ha                            => 'false',
  l3_ha_net_cidr                   => '169.254.192.0/18',
  manage_service                   => 'true',
  max_l3_agents_per_router         => '3',
  min_l3_agents_per_router         => '2',
  name                             => 'Neutron::Server',
  package_ensure                   => 'present',
  require                          => 'Class[Keystone::Python]',
  router_distributed               => 'false',
  router_scheduler_driver          => 'neutron.scheduler.l3_agent_scheduler.ChanceScheduler',
  rpc_workers                      => '4',
  sync_db                          => 'false',
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

exec { 'remove_neutron-server_override':
  before  => 'Service[neutron-server]',
  command => 'rm -f /etc/init/neutron-server.override',
  onlyif  => 'test -f /etc/init/neutron-server.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { 'create_neutron-server_override':
  ensure  => 'present',
  before  => ['Package[neutron-server]', 'Package[neutron-server]', 'Exec[remove_neutron-server_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/neutron-server.override',
}

neutron_api_config { 'filter:authtoken/admin_password':
  name   => 'filter:authtoken/admin_password',
  notify => 'Service[neutron-server]',
  secret => 'true',
  value  => 'muG6m84W',
}

neutron_api_config { 'filter:authtoken/admin_tenant_name':
  name   => 'filter:authtoken/admin_tenant_name',
  notify => 'Service[neutron-server]',
  value  => 'services',
}

neutron_api_config { 'filter:authtoken/admin_user':
  name   => 'filter:authtoken/admin_user',
  notify => 'Service[neutron-server]',
  value  => 'neutron',
}

neutron_api_config { 'filter:authtoken/auth_admin_prefix':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_admin_prefix',
  notify => 'Service[neutron-server]',
}

neutron_api_config { 'filter:authtoken/auth_host':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_host',
  notify => 'Service[neutron-server]',
}

neutron_api_config { 'filter:authtoken/auth_port':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_port',
  notify => 'Service[neutron-server]',
}

neutron_api_config { 'filter:authtoken/auth_protocol':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_protocol',
  notify => 'Service[neutron-server]',
}

neutron_api_config { 'filter:authtoken/auth_uri':
  name   => 'filter:authtoken/auth_uri',
  notify => 'Service[neutron-server]',
  value  => 'http://10.122.12.2:5000/',
}

neutron_api_config { 'filter:authtoken/identity_uri':
  name   => 'filter:authtoken/identity_uri',
  notify => 'Service[neutron-server]',
  value  => 'http://10.122.12.2:5000/',
}

neutron_config { 'DEFAULT/agent_down_time':
  name   => 'DEFAULT/agent_down_time',
  notify => 'Service[neutron-server]',
  value  => '30',
}

neutron_config { 'DEFAULT/allow_automatic_l3agent_failover':
  name   => 'DEFAULT/allow_automatic_l3agent_failover',
  notify => 'Service[neutron-server]',
  value  => 'true',
}

neutron_config { 'DEFAULT/api_workers':
  name   => 'DEFAULT/api_workers',
  notify => 'Service[neutron-server]',
  value  => '4',
}

neutron_config { 'DEFAULT/l3_ha':
  name   => 'DEFAULT/l3_ha',
  notify => 'Service[neutron-server]',
  value  => 'false',
}

neutron_config { 'DEFAULT/notify_nova_on_port_data_changes':
  name   => 'DEFAULT/notify_nova_on_port_data_changes',
  notify => 'Service[neutron-server]',
  value  => 'true',
}

neutron_config { 'DEFAULT/notify_nova_on_port_status_changes':
  name   => 'DEFAULT/notify_nova_on_port_status_changes',
  notify => 'Service[neutron-server]',
  value  => 'true',
}

neutron_config { 'DEFAULT/nova_admin_auth_url':
  name   => 'DEFAULT/nova_admin_auth_url',
  notify => 'Service[neutron-server]',
  value  => 'http://10.122.12.2:35357/v2.0/',
}

neutron_config { 'DEFAULT/nova_admin_password':
  name   => 'DEFAULT/nova_admin_password',
  notify => 'Service[neutron-server]',
  secret => 'true',
  value  => 'vhdwzqrw',
}

neutron_config { 'DEFAULT/nova_admin_username':
  name   => 'DEFAULT/nova_admin_username',
  notify => 'Service[neutron-server]',
  value  => 'nova',
}

neutron_config { 'DEFAULT/nova_region_name':
  name   => 'DEFAULT/nova_region_name',
  notify => 'Service[neutron-server]',
  value  => 'RegionOne',
}

neutron_config { 'DEFAULT/nova_url':
  name   => 'DEFAULT/nova_url',
  notify => 'Service[neutron-server]',
  value  => 'http://10.122.12.2:8774/v2',
}

neutron_config { 'DEFAULT/router_distributed':
  name   => 'DEFAULT/router_distributed',
  notify => 'Service[neutron-server]',
  value  => 'false',
}

neutron_config { 'DEFAULT/router_scheduler_driver':
  name   => 'DEFAULT/router_scheduler_driver',
  notify => 'Service[neutron-server]',
  value  => 'neutron.scheduler.l3_agent_scheduler.ChanceScheduler',
}

neutron_config { 'DEFAULT/rpc_workers':
  name   => 'DEFAULT/rpc_workers',
  notify => 'Service[neutron-server]',
  value  => '4',
}

neutron_config { 'DEFAULT/send_events_interval':
  name   => 'DEFAULT/send_events_interval',
  notify => 'Service[neutron-server]',
  value  => '2',
}

neutron_config { 'database/connection':
  name   => 'database/connection',
  notify => 'Service[neutron-server]',
  secret => 'true',
  value  => 'mysql://neutron:DVHUmPBa@10.122.12.2/neutron?&read_timeout=60',
}

neutron_config { 'database/idle_timeout':
  name   => 'database/idle_timeout',
  notify => 'Service[neutron-server]',
  value  => '3600',
}

neutron_config { 'database/max_overflow':
  name   => 'database/max_overflow',
  notify => 'Service[neutron-server]',
  value  => '20',
}

neutron_config { 'database/max_pool_size':
  name   => 'database/max_pool_size',
  notify => 'Service[neutron-server]',
  value  => '10',
}

neutron_config { 'database/max_retries':
  name   => 'database/max_retries',
  notify => 'Service[neutron-server]',
  value  => '-1',
}

neutron_config { 'database/min_pool_size':
  name   => 'database/min_pool_size',
  notify => 'Service[neutron-server]',
  value  => '1',
}

neutron_config { 'database/retry_interval':
  name   => 'database/retry_interval',
  notify => 'Service[neutron-server]',
  value  => '2',
}

neutron_config { 'keystone_authtoken/admin_password':
  name   => 'keystone_authtoken/admin_password',
  notify => 'Service[neutron-server]',
  secret => 'true',
  value  => 'muG6m84W',
}

neutron_config { 'keystone_authtoken/admin_tenant_name':
  name   => 'keystone_authtoken/admin_tenant_name',
  notify => 'Service[neutron-server]',
  value  => 'services',
}

neutron_config { 'keystone_authtoken/admin_user':
  name   => 'keystone_authtoken/admin_user',
  notify => 'Service[neutron-server]',
  value  => 'neutron',
}

neutron_config { 'keystone_authtoken/auth_admin_prefix':
  ensure => 'absent',
  name   => 'keystone_authtoken/auth_admin_prefix',
  notify => 'Service[neutron-server]',
}

neutron_config { 'keystone_authtoken/auth_host':
  ensure => 'absent',
  name   => 'keystone_authtoken/auth_host',
  notify => 'Service[neutron-server]',
}

neutron_config { 'keystone_authtoken/auth_port':
  ensure => 'absent',
  name   => 'keystone_authtoken/auth_port',
  notify => 'Service[neutron-server]',
}

neutron_config { 'keystone_authtoken/auth_protocol':
  ensure => 'absent',
  name   => 'keystone_authtoken/auth_protocol',
  notify => 'Service[neutron-server]',
}

neutron_config { 'keystone_authtoken/auth_region':
  name   => 'keystone_authtoken/auth_region',
  notify => 'Service[neutron-server]',
  value  => 'RegionOne',
}

neutron_config { 'keystone_authtoken/auth_uri':
  name   => 'keystone_authtoken/auth_uri',
  notify => 'Service[neutron-server]',
  value  => 'http://10.122.12.2:5000/',
}

neutron_config { 'keystone_authtoken/identity_uri':
  name   => 'keystone_authtoken/identity_uri',
  notify => 'Service[neutron-server]',
  value  => 'http://10.122.12.2:5000/',
}

nova_admin_tenant_id_setter { 'nova_admin_tenant_id':
  ensure           => 'present',
  auth_password    => 'vhdwzqrw',
  auth_tenant_name => 'services',
  auth_url         => 'http://10.122.12.2:35357/v2.0/',
  auth_username    => 'nova',
  name             => 'nova_admin_tenant_id',
  notify           => 'Service[neutron-server]',
  tenant_name      => 'services',
}

package { 'neutron-server':
  ensure => 'present',
  before => ['Neutron_api_config[filter:authtoken/admin_tenant_name]', 'Neutron_api_config[filter:authtoken/admin_user]', 'Neutron_api_config[filter:authtoken/admin_password]', 'Neutron_api_config[filter:authtoken/auth_admin_prefix]', 'Neutron_api_config[filter:authtoken/auth_host]', 'Neutron_api_config[filter:authtoken/auth_port]', 'Neutron_api_config[filter:authtoken/auth_protocol]', 'Neutron_api_config[filter:authtoken/auth_uri]', 'Neutron_api_config[filter:authtoken/identity_uri]', 'Neutron_config[database/connection]', 'Neutron_config[database/idle_timeout]', 'Neutron_config[database/min_pool_size]', 'Neutron_config[database/max_retries]', 'Neutron_config[database/retry_interval]', 'Neutron_config[database/max_pool_size]', 'Neutron_config[database/max_overflow]', 'Neutron_config[DEFAULT/l3_ha]', 'Neutron_config[DEFAULT/api_workers]', 'Neutron_config[DEFAULT/rpc_workers]', 'Neutron_config[DEFAULT/agent_down_time]', 'Neutron_config[DEFAULT/router_scheduler_driver]', 'Neutron_config[DEFAULT/router_distributed]', 'Neutron_config[DEFAULT/allow_automatic_l3agent_failover]', 'Neutron_config[keystone_authtoken/admin_tenant_name]', 'Neutron_config[keystone_authtoken/admin_user]', 'Neutron_config[keystone_authtoken/admin_password]', 'Neutron_config[keystone_authtoken/auth_admin_prefix]', 'Neutron_config[keystone_authtoken/auth_host]', 'Neutron_config[keystone_authtoken/auth_port]', 'Neutron_config[keystone_authtoken/auth_protocol]', 'Neutron_config[keystone_authtoken/auth_uri]', 'Neutron_config[keystone_authtoken/auth_region]', 'Neutron_config[keystone_authtoken/identity_uri]', 'Neutron_config[DEFAULT/notify_nova_on_port_status_changes]', 'Neutron_config[DEFAULT/notify_nova_on_port_data_changes]', 'Neutron_config[DEFAULT/send_events_interval]', 'Neutron_config[DEFAULT/nova_url]', 'Neutron_config[DEFAULT/nova_admin_auth_url]', 'Neutron_config[DEFAULT/nova_admin_username]', 'Neutron_config[DEFAULT/nova_admin_password]', 'Neutron_config[DEFAULT/nova_region_name]', 'Service[neutron-server]', 'Class[Neutron::Policy]', 'Exec[remove_neutron-server_override]', 'Exec[remove_neutron-server_override]'],
  name   => 'neutron-server',
  tag    => ['openstack', 'neutron-package'],
}

package { 'neutron':
  ensure => 'installed',
  name   => 'binutils',
}

package { 'python-keystone':
  ensure => 'present',
  name   => 'python-keystone',
}

package { 'python-mysqldb':
  ensure => 'present',
  name   => 'python-mysqldb',
}

service { 'neutron-server':
  ensure     => 'stopped',
  enable     => 'false',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'neutron-server',
  require    => 'Class[Neutron]',
  tag        => 'neutron-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'neutron-server':
  name         => 'neutron-server',
  package_name => 'neutron-server',
  service_name => 'neutron-server',
}

