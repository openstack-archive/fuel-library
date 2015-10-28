class { 'Cinder::Client':
  name           => 'Cinder::Client',
  package_ensure => 'present',
}

class { 'Cinder::Params':
  name => 'Cinder::Params',
}

class { 'Keystone::Params':
  name => 'Keystone::Params',
}

class { 'Keystone::Python':
  ensure              => 'present',
  client_package_name => 'python-keystone',
  name                => 'Keystone::Python',
}

class { 'Nova::Api':
  admin_password        => 'UyrT2Ama',
  admin_tenant_name     => 'services',
  admin_user            => 'nova',
  api_bind_address      => '192.168.0.3',
  auth_admin_prefix     => 'false',
  auth_host             => '127.0.0.1',
  auth_port             => '35357',
  auth_protocol         => 'http',
  auth_uri              => 'false',
  auth_version          => 'false',
  ec2_workers           => '4',
  enabled               => 'true',
  enabled_apis          => 'metadata',
  ensure_package        => 'installed',
  identity_uri          => 'false',
  keystone_ec2_url      => 'false',
  manage_service        => 'true',
  metadata_listen       => '0.0.0.0',
  metadata_workers      => '4',
  name                  => 'Nova::Api',
  osapi_compute_workers => '1',
  osapi_v3              => 'false',
  ratelimits            => {'DELETE' => '100000', 'GET' => '100000', 'POST' => '100000', 'POST_SERVERS' => '100000', 'PUT' => '1000'},
  ratelimits_factory    => 'nova.api.openstack.compute.limits:RateLimitingMiddleware.factory',
  require               => 'Class[Keystone::Python]',
  sync_db               => 'true',
  use_forwarded_for     => 'false',
  validate              => 'false',
  validation_options    => {},
  volume_api_class      => 'nova.volume.cinder.API',
}

class { 'Nova::Db::Sync':
  name => 'Nova::Db::Sync',
}

class { 'Nova::Db':
  name => 'Nova::Db',
}

class { 'Nova::Network::Flatdhcp':
  dhcp_domain         => 'novalocal',
  dhcpbridge          => '/usr/bin/nova-dhcpbridge',
  dhcpbridge_flagfile => '/etc/nova/nova.conf',
  fixed_range         => '10.0.0.0/16',
  flat_injected       => 'false',
  flat_network_bridge => 'br100',
  force_dhcp_release  => 'true',
  name                => 'Nova::Network::Flatdhcp',
  public_interface    => 'br-ex',
}

class { 'Nova::Network':
  config_overrides => {},
  create_networks  => 'true',
  dns1             => '8.8.4.4',
  dns2             => '8.8.8.8',
  enabled          => 'true',
  ensure_package   => 'installed',
  fixed_range      => '10.0.0.0/16',
  floating_range   => 'false',
  install_service  => 'true',
  name             => 'Nova::Network',
  network_manager  => 'nova.network.manager.FlatDHCPManager',
  network_size     => '65536',
  num_networks     => '1',
  public_interface => 'br-ex',
}

class { 'Nova::Params':
  name => 'Nova::Params',
}

class { 'Nova::Policy':
  name        => 'Nova::Policy',
  notify      => 'Service[nova-api]',
  policies    => {},
  policy_path => '/etc/nova/policy.json',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Sysctl::Base':
  name => 'Sysctl::Base',
}

class { 'main':
  name => 'main',
}

exec { 'networking-refresh':
  command     => '/bin/echo "networking-refresh has been refreshed"',
  refreshonly => 'true',
}

exec { 'nova-db-sync':
  before      => 'Nova_network[nova-vm-net]',
  command     => '/usr/bin/nova-manage db sync',
  logoutput   => 'on_failure',
  notify      => ['Service[nova-api]', 'Service[nova-network]', 'Service[nova-api]', 'Service[nova-network]'],
  refreshonly => 'true',
}

exec { 'post-nova_config':
  command     => '/bin/echo "Nova config has changed"',
  notify      => ['Exec[nova-db-sync]', 'Service[nova-api]', 'Service[nova-network]'],
  refreshonly => 'true',
}

exec { 'remove_nova-api_override':
  before  => ['Service[nova-api]', 'Service[nova-api]'],
  command => 'rm -f /etc/init/nova-api.override',
  onlyif  => 'test -f /etc/init/nova-api.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-network_override':
  before  => ['Service[nova-network]', 'Service[nova-network]'],
  command => 'rm -f /etc/init/nova-network.override',
  onlyif  => 'test -f /etc/init/nova-network.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/etc/nova/nova.conf':
  ensure => 'present',
  before => 'Nova_network[nova-vm-net]',
  path   => '/etc/nova/nova.conf',
}

file { '/etc/sysctl.conf':
  ensure => 'present',
  group  => '0',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/sysctl.conf',
}

file { 'create_nova-api_override':
  ensure  => 'present',
  before  => ['Package[nova-api]', 'Package[nova-api]', 'Exec[remove_nova-api_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-api.override',
}

file { 'create_nova-network_override':
  ensure  => 'present',
  before  => ['Package[nova-network]', 'Package[nova-network]', 'Exec[remove_nova-network_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-network.override',
}

nova::generic_service { 'api':
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'api',
  package_name   => 'nova-api',
  service_name   => 'nova-api',
  subscribe      => 'Class[Cinder::Client]',
}

nova::generic_service { 'network':
  before         => 'Exec[networking-refresh]',
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'network',
  package_name   => 'nova-network',
  service_name   => 'nova-network',
}

nova::manage::network { 'nova-vm-net':
  dns1         => '8.8.4.4',
  dns2         => '8.8.8.8',
  label        => 'novanetwork',
  name         => 'nova-vm-net',
  network      => '10.0.0.0/16',
  network_size => '65536',
  num_networks => '1',
}

nova_config { 'DEFAULT/dhcp_domain':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/dhcp_domain',
  value  => 'novalocal',
}

nova_config { 'DEFAULT/dhcpbridge':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/dhcpbridge',
  value  => '/usr/bin/nova-dhcpbridge',
}

nova_config { 'DEFAULT/dhcpbridge_flagfile':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/dhcpbridge_flagfile',
  value  => '/etc/nova/nova.conf',
}

nova_config { 'DEFAULT/ec2_listen':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/ec2_listen',
  value  => '192.168.0.3',
}

nova_config { 'DEFAULT/ec2_workers':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/ec2_workers',
  value  => '4',
}

nova_config { 'DEFAULT/enabled_apis':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/enabled_apis',
  value  => 'metadata',
}

nova_config { 'DEFAULT/fixed_range':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/fixed_range',
  value  => '10.0.0.0/16',
}

nova_config { 'DEFAULT/flat_injected':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/flat_injected',
  value  => 'false',
}

nova_config { 'DEFAULT/flat_interface':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/flat_interface',
}

nova_config { 'DEFAULT/flat_network_bridge':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/flat_network_bridge',
  value  => 'br100',
}

nova_config { 'DEFAULT/force_dhcp_release':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/force_dhcp_release',
  value  => 'true',
}

nova_config { 'DEFAULT/force_snat_range':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/force_snat_range',
  value  => '0.0.0.0/0',
}

nova_config { 'DEFAULT/keystone_ec2_url':
  ensure => 'absent',
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/keystone_ec2_url',
}

nova_config { 'DEFAULT/metadata_host':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/metadata_host',
  value  => '192.168.0.3',
}

nova_config { 'DEFAULT/metadata_listen':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/metadata_listen',
  value  => '0.0.0.0',
}

nova_config { 'DEFAULT/metadata_workers':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/metadata_workers',
  value  => '4',
}

nova_config { 'DEFAULT/multi_host':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/multi_host',
  value  => 'True',
}

nova_config { 'DEFAULT/network_manager':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/network_manager',
  value  => 'nova.network.manager.FlatDHCPManager',
}

nova_config { 'DEFAULT/osapi_compute_listen':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/osapi_compute_listen',
  value  => '192.168.0.3',
}

nova_config { 'DEFAULT/osapi_compute_workers':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/osapi_compute_workers',
  value  => '1',
}

nova_config { 'DEFAULT/osapi_volume_listen':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/osapi_volume_listen',
  value  => '192.168.0.3',
}

nova_config { 'DEFAULT/public_interface':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/public_interface',
  value  => 'br-ex',
}

nova_config { 'DEFAULT/send_arp_for_ha':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/send_arp_for_ha',
  value  => 'True',
}

nova_config { 'DEFAULT/use_forwarded_for':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/use_forwarded_for',
  value  => 'false',
}

nova_config { 'DEFAULT/volume_api_class':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'DEFAULT/volume_api_class',
  value  => 'nova.volume.cinder.API',
}

nova_config { 'keystone_authtoken/admin_password':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'keystone_authtoken/admin_password',
  secret => 'true',
  value  => 'UyrT2Ama',
}

nova_config { 'keystone_authtoken/admin_tenant_name':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'keystone_authtoken/admin_tenant_name',
  value  => 'services',
}

nova_config { 'keystone_authtoken/admin_user':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'keystone_authtoken/admin_user',
  value  => 'nova',
}

nova_config { 'keystone_authtoken/auth_admin_prefix':
  ensure => 'absent',
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'keystone_authtoken/auth_admin_prefix',
}

nova_config { 'keystone_authtoken/auth_host':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'keystone_authtoken/auth_host',
  value  => '127.0.0.1',
}

nova_config { 'keystone_authtoken/auth_port':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'keystone_authtoken/auth_port',
  value  => '35357',
}

nova_config { 'keystone_authtoken/auth_protocol':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'keystone_authtoken/auth_protocol',
  value  => 'http',
}

nova_config { 'keystone_authtoken/auth_uri':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'keystone_authtoken/auth_uri',
  value  => 'http://127.0.0.1:5000/',
}

nova_config { 'keystone_authtoken/auth_version':
  ensure => 'absent',
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'keystone_authtoken/auth_version',
}

nova_config { 'keystone_authtoken/identity_uri':
  ensure => 'absent',
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'keystone_authtoken/identity_uri',
}

nova_config { 'neutron/metadata_proxy_shared_secret':
  ensure => 'absent',
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'neutron/metadata_proxy_shared_secret',
}

nova_config { 'neutron/service_metadata_proxy':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'neutron/service_metadata_proxy',
  value  => 'false',
}

nova_config { 'osapi_v3/enabled':
  before => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  name   => 'osapi_v3/enabled',
  value  => 'false',
}

nova_network { 'nova-vm-net':
  ensure       => 'present',
  dns1         => '8.8.4.4',
  dns2         => '8.8.8.8',
  label        => 'novanetwork',
  network      => '10.0.0.0/16',
  network_size => '65536',
  num_networks => '1',
}

nova_paste_api_ini { 'filter:authtoken/admin_password':
  ensure => 'absent',
  name   => 'filter:authtoken/admin_password',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
}

nova_paste_api_ini { 'filter:authtoken/admin_tenant_name':
  ensure => 'absent',
  name   => 'filter:authtoken/admin_tenant_name',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
}

nova_paste_api_ini { 'filter:authtoken/admin_user':
  ensure => 'absent',
  name   => 'filter:authtoken/admin_user',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
}

nova_paste_api_ini { 'filter:authtoken/auth_admin_prefix':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_admin_prefix',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
}

nova_paste_api_ini { 'filter:authtoken/auth_host':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_host',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
}

nova_paste_api_ini { 'filter:authtoken/auth_port':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_port',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
}

nova_paste_api_ini { 'filter:authtoken/auth_protocol':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_protocol',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
}

nova_paste_api_ini { 'filter:authtoken/auth_uri':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_uri',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
}

nova_paste_api_ini { 'filter:ratelimit/limits':
  name   => 'filter:ratelimit/limits',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
  value  => {'DELETE' => '100000', 'GET' => '100000', 'POST' => '100000', 'POST_SERVERS' => '100000', 'PUT' => '1000'},
}

nova_paste_api_ini { 'filter:ratelimit/paste.filter_factory':
  name   => 'filter:ratelimit/paste.filter_factory',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
  value  => 'nova.api.openstack.compute.limits:RateLimitingMiddleware.factory',
}

package { 'nova-api':
  ensure => 'installed',
  before => ['Service[nova-api]', 'Service[nova-api]', 'Exec[remove_nova-api_override]', 'Exec[remove_nova-api_override]'],
  name   => 'nova-api',
  notify => ['Service[nova-api]', 'Exec[nova-db-sync]'],
  tag    => ['openstack', 'nova-package'],
}

package { 'nova-common':
  ensure => 'installed',
  before => ['Class[Nova::Api]', 'Class[Nova::Policy]'],
  name   => 'binutils',
}

package { 'nova-network':
  ensure => 'installed',
  before => ['Exec[remove_nova-network_override]', 'Exec[remove_nova-network_override]', 'Service[nova-network]', 'Service[nova-network]'],
  name   => 'nova-network',
  notify => ['Service[nova-network]', 'Exec[nova-db-sync]'],
  tag    => ['openstack', 'nova-package'],
}

package { 'python-cinderclient':
  ensure => 'present',
  name   => 'python-cinderclient',
  tag    => 'openstack',
}

package { 'python-keystone':
  ensure => 'present',
  name   => 'python-keystone',
}

package { 'python-memcache':
  ensure => 'present',
  before => 'Nova::Generic_service[api]',
  name   => 'python-memcache',
}

service { 'nova-api':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'nova-api',
  require   => 'Package[nova-common]',
  tag       => 'nova-service',
}

service { 'nova-network':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'nova-network',
  require   => 'Package[nova-common]',
  tag       => 'nova-service',
}

stage { 'main':
  name => 'main',
}

sysctl::value { 'net.ipv4.ip_forward':
  key     => 'net.ipv4.ip_forward',
  name    => 'net.ipv4.ip_forward',
  require => 'Class[Sysctl::Base]',
  value   => '1',
}

sysctl { 'net.ipv4.ip_forward':
  before => 'Sysctl_runtime[net.ipv4.ip_forward]',
  name   => 'net.ipv4.ip_forward',
  val    => '1',
}

sysctl_runtime { 'net.ipv4.ip_forward':
  name => 'net.ipv4.ip_forward',
  val  => '1',
}

tweaks::ubuntu_service_override { 'nova-api':
  name         => 'nova-api',
  package_name => 'nova-api',
  service_name => 'nova-api',
}

tweaks::ubuntu_service_override { 'nova-network':
  name         => 'nova-network',
  package_name => 'nova-network',
  service_name => 'nova-network',
}

