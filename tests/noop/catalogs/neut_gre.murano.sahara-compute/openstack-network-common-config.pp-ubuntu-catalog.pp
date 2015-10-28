class { 'Neutron::Params':
  name => 'Neutron::Params',
}

class { 'Neutron':
  advertise_mtu                      => 'true',
  allow_bulk                         => 'true',
  allow_overlapping_ips              => 'true',
  allow_pagination                   => 'false',
  allow_sorting                      => 'false',
  auth_strategy                      => 'keystone',
  base_mac                           => 'fa:16:3e:00:00:00',
  bind_host                          => '192.168.0.5',
  bind_port                          => '9696',
  ca_file                            => 'false',
  cert_file                          => 'false',
  control_exchange                   => 'neutron',
  core_plugin                        => 'neutron.plugins.ml2.plugin.Ml2Plugin',
  debug                              => 'false',
  dhcp_agent_notification            => 'true',
  dhcp_agents_per_network            => '2',
  dhcp_lease_duration                => '600',
  enabled                            => 'true',
  key_file                           => 'false',
  kombu_reconnect_delay              => '5.0',
  kombu_ssl_version                  => 'TLSv1',
  lock_path                          => '/var/lib/neutron/lock',
  log_dir                            => '/var/log/neutron',
  log_facility                       => 'LOG_LOCAL4',
  log_file                           => 'false',
  mac_generation_retries             => '32',
  memcache_servers                   => 'false',
  name                               => 'Neutron',
  network_device_mtu                 => '1450',
  package_ensure                     => 'present',
  qpid_heartbeat                     => '60',
  qpid_hostname                      => 'localhost',
  qpid_password                      => 'guest',
  qpid_port                          => '5672',
  qpid_protocol                      => 'tcp',
  qpid_reconnect                     => 'true',
  qpid_reconnect_interval            => '0',
  qpid_reconnect_interval_max        => '0',
  qpid_reconnect_interval_min        => '0',
  qpid_reconnect_limit               => '0',
  qpid_reconnect_timeout             => '0',
  qpid_tcp_nodelay                   => 'true',
  qpid_username                      => 'guest',
  rabbit_heartbeat_rate              => '2',
  rabbit_heartbeat_timeout_threshold => '0',
  rabbit_host                        => 'localhost',
  rabbit_hosts                       => ['192.168.0.2:5673', ' 192.168.0.3:5673', ' 192.168.0.4:5673'],
  rabbit_password                    => 'c7fQJeSe',
  rabbit_port                        => '5672',
  rabbit_use_ssl                     => 'false',
  rabbit_user                        => 'nova',
  rabbit_virtual_host                => '/',
  report_interval                    => '10',
  root_helper                        => 'sudo neutron-rootwrap /etc/neutron/rootwrap.conf',
  rpc_backend                        => 'rabbit',
  rpc_response_timeout               => '60',
  service_plugins                    => ['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin', 'neutron.services.metering.metering_plugin.MeteringPlugin'],
  state_path                         => '/var/lib/neutron',
  use_ssl                            => 'false',
  use_stderr                         => 'false',
  use_syslog                         => 'true',
  verbose                            => 'true',
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

file { '/etc/sysctl.conf':
  ensure => 'present',
  group  => '0',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/sysctl.conf',
}

neutron_config { 'DEFAULT/advertise_mtu':
  name  => 'DEFAULT/advertise_mtu',
  value => 'true',
}

neutron_config { 'DEFAULT/allow_bulk':
  name  => 'DEFAULT/allow_bulk',
  value => 'true',
}

neutron_config { 'DEFAULT/allow_overlapping_ips':
  name  => 'DEFAULT/allow_overlapping_ips',
  value => 'true',
}

neutron_config { 'DEFAULT/allow_pagination':
  name  => 'DEFAULT/allow_pagination',
  value => 'false',
}

neutron_config { 'DEFAULT/allow_sorting':
  name  => 'DEFAULT/allow_sorting',
  value => 'false',
}

neutron_config { 'DEFAULT/api_extensions_path':
  name => 'DEFAULT/api_extensions_path',
}

neutron_config { 'DEFAULT/auth_strategy':
  name  => 'DEFAULT/auth_strategy',
  value => 'keystone',
}

neutron_config { 'DEFAULT/base_mac':
  name  => 'DEFAULT/base_mac',
  value => 'fa:16:3e:00:00:00',
}

neutron_config { 'DEFAULT/bind_host':
  name  => 'DEFAULT/bind_host',
  value => '192.168.0.5',
}

neutron_config { 'DEFAULT/bind_port':
  name  => 'DEFAULT/bind_port',
  value => '9696',
}

neutron_config { 'DEFAULT/control_exchange':
  name  => 'DEFAULT/control_exchange',
  value => 'neutron',
}

neutron_config { 'DEFAULT/core_plugin':
  name  => 'DEFAULT/core_plugin',
  value => 'neutron.plugins.ml2.plugin.Ml2Plugin',
}

neutron_config { 'DEFAULT/debug':
  name  => 'DEFAULT/debug',
  value => 'false',
}

neutron_config { 'DEFAULT/dhcp_agent_notification':
  name  => 'DEFAULT/dhcp_agent_notification',
  value => 'true',
}

neutron_config { 'DEFAULT/dhcp_agents_per_network':
  name  => 'DEFAULT/dhcp_agents_per_network',
  value => '2',
}

neutron_config { 'DEFAULT/dhcp_lease_duration':
  name  => 'DEFAULT/dhcp_lease_duration',
  value => '600',
}

neutron_config { 'DEFAULT/lock_path':
  name  => 'DEFAULT/lock_path',
  value => '/var/lib/neutron/lock',
}

neutron_config { 'DEFAULT/log_dir':
  name  => 'DEFAULT/log_dir',
  value => '/var/log/neutron',
}

neutron_config { 'DEFAULT/log_file':
  ensure => 'absent',
  name   => 'DEFAULT/log_file',
}

neutron_config { 'DEFAULT/mac_generation_retries':
  name  => 'DEFAULT/mac_generation_retries',
  value => '32',
}

neutron_config { 'DEFAULT/memcached_servers':
  ensure => 'absent',
  name   => 'DEFAULT/memcached_servers',
}

neutron_config { 'DEFAULT/network_device_mtu':
  name  => 'DEFAULT/network_device_mtu',
  value => '1450',
}

neutron_config { 'DEFAULT/rpc_backend':
  name  => 'DEFAULT/rpc_backend',
  value => 'rabbit',
}

neutron_config { 'DEFAULT/rpc_response_timeout':
  name  => 'DEFAULT/rpc_response_timeout',
  value => '60',
}

neutron_config { 'DEFAULT/service_plugins':
  name  => 'DEFAULT/service_plugins',
  value => 'neutron.services.l3_router.l3_router_plugin.L3RouterPlugin,neutron.services.metering.metering_plugin.MeteringPlugin',
}

neutron_config { 'DEFAULT/ssl_ca_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_ca_file',
}

neutron_config { 'DEFAULT/ssl_cert_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_cert_file',
}

neutron_config { 'DEFAULT/ssl_key_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_key_file',
}

neutron_config { 'DEFAULT/state_path':
  name  => 'DEFAULT/state_path',
  value => '/var/lib/neutron',
}

neutron_config { 'DEFAULT/syslog_log_facility':
  name  => 'DEFAULT/syslog_log_facility',
  value => 'LOG_LOCAL4',
}

neutron_config { 'DEFAULT/use_ssl':
  name  => 'DEFAULT/use_ssl',
  value => 'false',
}

neutron_config { 'DEFAULT/use_stderr':
  name  => 'DEFAULT/use_stderr',
  value => 'false',
}

neutron_config { 'DEFAULT/use_syslog':
  name  => 'DEFAULT/use_syslog',
  value => 'true',
}

neutron_config { 'DEFAULT/use_syslog_rfc_format':
  name  => 'DEFAULT/use_syslog_rfc_format',
  value => 'true',
}

neutron_config { 'DEFAULT/verbose':
  name  => 'DEFAULT/verbose',
  value => 'true',
}

neutron_config { 'agent/report_interval':
  name  => 'agent/report_interval',
  value => '10',
}

neutron_config { 'agent/root_helper':
  name  => 'agent/root_helper',
  value => 'sudo neutron-rootwrap /etc/neutron/rootwrap.conf',
}

neutron_config { 'oslo_messaging_rabbit/heartbeat_rate':
  name  => 'oslo_messaging_rabbit/heartbeat_rate',
  value => '2',
}

neutron_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold':
  name  => 'oslo_messaging_rabbit/heartbeat_timeout_threshold',
  value => '0',
}

neutron_config { 'oslo_messaging_rabbit/kombu_reconnect_delay':
  name  => 'oslo_messaging_rabbit/kombu_reconnect_delay',
  value => '5.0',
}

neutron_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_ca_certs',
}

neutron_config { 'oslo_messaging_rabbit/kombu_ssl_certfile':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_certfile',
}

neutron_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_keyfile',
}

neutron_config { 'oslo_messaging_rabbit/kombu_ssl_version':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_version',
}

neutron_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  name  => 'oslo_messaging_rabbit/rabbit_ha_queues',
  value => 'true',
}

neutron_config { 'oslo_messaging_rabbit/rabbit_hosts':
  name  => 'oslo_messaging_rabbit/rabbit_hosts',
  value => '192.168.0.2:5673, 192.168.0.3:5673, 192.168.0.4:5673',
}

neutron_config { 'oslo_messaging_rabbit/rabbit_password':
  name   => 'oslo_messaging_rabbit/rabbit_password',
  secret => 'true',
  value  => 'c7fQJeSe',
}

neutron_config { 'oslo_messaging_rabbit/rabbit_use_ssl':
  name  => 'oslo_messaging_rabbit/rabbit_use_ssl',
  value => 'false',
}

neutron_config { 'oslo_messaging_rabbit/rabbit_userid':
  name  => 'oslo_messaging_rabbit/rabbit_userid',
  value => 'nova',
}

neutron_config { 'oslo_messaging_rabbit/rabbit_virtual_host':
  name  => 'oslo_messaging_rabbit/rabbit_virtual_host',
  value => '/',
}

package { 'neutron':
  ensure => 'present',
  name   => 'neutron-common',
  tag    => ['openstack', 'neutron-package'],
}

stage { 'main':
  name => 'main',
}

sysctl::value { 'net.ipv4.ip_forward':
  before  => ['Neutron_config[DEFAULT/verbose]', 'Neutron_config[DEFAULT/debug]', 'Neutron_config[DEFAULT/use_stderr]', 'Neutron_config[DEFAULT/bind_host]', 'Neutron_config[DEFAULT/bind_port]', 'Neutron_config[DEFAULT/auth_strategy]', 'Neutron_config[DEFAULT/core_plugin]', 'Neutron_config[DEFAULT/base_mac]', 'Neutron_config[DEFAULT/mac_generation_retries]', 'Neutron_config[DEFAULT/dhcp_lease_duration]', 'Neutron_config[DEFAULT/dhcp_agents_per_network]', 'Neutron_config[DEFAULT/dhcp_agent_notification]', 'Neutron_config[DEFAULT/advertise_mtu]', 'Neutron_config[DEFAULT/allow_bulk]', 'Neutron_config[DEFAULT/allow_pagination]', 'Neutron_config[DEFAULT/allow_sorting]', 'Neutron_config[DEFAULT/allow_overlapping_ips]', 'Neutron_config[DEFAULT/control_exchange]', 'Neutron_config[DEFAULT/rpc_backend]', 'Neutron_config[DEFAULT/api_extensions_path]', 'Neutron_config[DEFAULT/state_path]', 'Neutron_config[DEFAULT/lock_path]', 'Neutron_config[DEFAULT/rpc_response_timeout]', 'Neutron_config[agent/root_helper]', 'Neutron_config[agent/report_interval]', 'Neutron_config[DEFAULT/log_dir]', 'Neutron_config[DEFAULT/log_file]', 'Neutron_config[DEFAULT/network_device_mtu]', 'Neutron_config[DEFAULT/service_plugins]', 'Neutron_config[DEFAULT/memcached_servers]', 'Neutron_config[oslo_messaging_rabbit/rabbit_hosts]', 'Neutron_config[oslo_messaging_rabbit/rabbit_ha_queues]', 'Neutron_config[oslo_messaging_rabbit/rabbit_userid]', 'Neutron_config[oslo_messaging_rabbit/rabbit_password]', 'Neutron_config[oslo_messaging_rabbit/rabbit_virtual_host]', 'Neutron_config[oslo_messaging_rabbit/heartbeat_timeout_threshold]', 'Neutron_config[oslo_messaging_rabbit/heartbeat_rate]', 'Neutron_config[oslo_messaging_rabbit/rabbit_use_ssl]', 'Neutron_config[oslo_messaging_rabbit/kombu_reconnect_delay]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_ca_certs]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_certfile]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_keyfile]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_version]', 'Neutron_config[DEFAULT/use_ssl]', 'Neutron_config[DEFAULT/ssl_cert_file]', 'Neutron_config[DEFAULT/ssl_key_file]', 'Neutron_config[DEFAULT/ssl_ca_file]', 'Neutron_config[DEFAULT/use_syslog]', 'Neutron_config[DEFAULT/syslog_log_facility]', 'Neutron_config[DEFAULT/use_syslog_rfc_format]'],
  key     => 'net.ipv4.ip_forward',
  name    => 'net.ipv4.ip_forward',
  require => 'Class[Sysctl::Base]',
  value   => '1',
}

sysctl::value { 'net.ipv4.neigh.default.gc_thresh1':
  before  => ['Neutron_config[DEFAULT/verbose]', 'Neutron_config[DEFAULT/debug]', 'Neutron_config[DEFAULT/use_stderr]', 'Neutron_config[DEFAULT/bind_host]', 'Neutron_config[DEFAULT/bind_port]', 'Neutron_config[DEFAULT/auth_strategy]', 'Neutron_config[DEFAULT/core_plugin]', 'Neutron_config[DEFAULT/base_mac]', 'Neutron_config[DEFAULT/mac_generation_retries]', 'Neutron_config[DEFAULT/dhcp_lease_duration]', 'Neutron_config[DEFAULT/dhcp_agents_per_network]', 'Neutron_config[DEFAULT/dhcp_agent_notification]', 'Neutron_config[DEFAULT/advertise_mtu]', 'Neutron_config[DEFAULT/allow_bulk]', 'Neutron_config[DEFAULT/allow_pagination]', 'Neutron_config[DEFAULT/allow_sorting]', 'Neutron_config[DEFAULT/allow_overlapping_ips]', 'Neutron_config[DEFAULT/control_exchange]', 'Neutron_config[DEFAULT/rpc_backend]', 'Neutron_config[DEFAULT/api_extensions_path]', 'Neutron_config[DEFAULT/state_path]', 'Neutron_config[DEFAULT/lock_path]', 'Neutron_config[DEFAULT/rpc_response_timeout]', 'Neutron_config[agent/root_helper]', 'Neutron_config[agent/report_interval]', 'Neutron_config[DEFAULT/log_dir]', 'Neutron_config[DEFAULT/log_file]', 'Neutron_config[DEFAULT/network_device_mtu]', 'Neutron_config[DEFAULT/service_plugins]', 'Neutron_config[DEFAULT/memcached_servers]', 'Neutron_config[oslo_messaging_rabbit/rabbit_hosts]', 'Neutron_config[oslo_messaging_rabbit/rabbit_ha_queues]', 'Neutron_config[oslo_messaging_rabbit/rabbit_userid]', 'Neutron_config[oslo_messaging_rabbit/rabbit_password]', 'Neutron_config[oslo_messaging_rabbit/rabbit_virtual_host]', 'Neutron_config[oslo_messaging_rabbit/heartbeat_timeout_threshold]', 'Neutron_config[oslo_messaging_rabbit/heartbeat_rate]', 'Neutron_config[oslo_messaging_rabbit/rabbit_use_ssl]', 'Neutron_config[oslo_messaging_rabbit/kombu_reconnect_delay]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_ca_certs]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_certfile]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_keyfile]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_version]', 'Neutron_config[DEFAULT/use_ssl]', 'Neutron_config[DEFAULT/ssl_cert_file]', 'Neutron_config[DEFAULT/ssl_key_file]', 'Neutron_config[DEFAULT/ssl_ca_file]', 'Neutron_config[DEFAULT/use_syslog]', 'Neutron_config[DEFAULT/syslog_log_facility]', 'Neutron_config[DEFAULT/use_syslog_rfc_format]'],
  key     => 'net.ipv4.neigh.default.gc_thresh1',
  name    => 'net.ipv4.neigh.default.gc_thresh1',
  require => 'Class[Sysctl::Base]',
  value   => '1024',
}

sysctl::value { 'net.ipv4.neigh.default.gc_thresh2':
  before  => ['Neutron_config[DEFAULT/verbose]', 'Neutron_config[DEFAULT/debug]', 'Neutron_config[DEFAULT/use_stderr]', 'Neutron_config[DEFAULT/bind_host]', 'Neutron_config[DEFAULT/bind_port]', 'Neutron_config[DEFAULT/auth_strategy]', 'Neutron_config[DEFAULT/core_plugin]', 'Neutron_config[DEFAULT/base_mac]', 'Neutron_config[DEFAULT/mac_generation_retries]', 'Neutron_config[DEFAULT/dhcp_lease_duration]', 'Neutron_config[DEFAULT/dhcp_agents_per_network]', 'Neutron_config[DEFAULT/dhcp_agent_notification]', 'Neutron_config[DEFAULT/advertise_mtu]', 'Neutron_config[DEFAULT/allow_bulk]', 'Neutron_config[DEFAULT/allow_pagination]', 'Neutron_config[DEFAULT/allow_sorting]', 'Neutron_config[DEFAULT/allow_overlapping_ips]', 'Neutron_config[DEFAULT/control_exchange]', 'Neutron_config[DEFAULT/rpc_backend]', 'Neutron_config[DEFAULT/api_extensions_path]', 'Neutron_config[DEFAULT/state_path]', 'Neutron_config[DEFAULT/lock_path]', 'Neutron_config[DEFAULT/rpc_response_timeout]', 'Neutron_config[agent/root_helper]', 'Neutron_config[agent/report_interval]', 'Neutron_config[DEFAULT/log_dir]', 'Neutron_config[DEFAULT/log_file]', 'Neutron_config[DEFAULT/network_device_mtu]', 'Neutron_config[DEFAULT/service_plugins]', 'Neutron_config[DEFAULT/memcached_servers]', 'Neutron_config[oslo_messaging_rabbit/rabbit_hosts]', 'Neutron_config[oslo_messaging_rabbit/rabbit_ha_queues]', 'Neutron_config[oslo_messaging_rabbit/rabbit_userid]', 'Neutron_config[oslo_messaging_rabbit/rabbit_password]', 'Neutron_config[oslo_messaging_rabbit/rabbit_virtual_host]', 'Neutron_config[oslo_messaging_rabbit/heartbeat_timeout_threshold]', 'Neutron_config[oslo_messaging_rabbit/heartbeat_rate]', 'Neutron_config[oslo_messaging_rabbit/rabbit_use_ssl]', 'Neutron_config[oslo_messaging_rabbit/kombu_reconnect_delay]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_ca_certs]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_certfile]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_keyfile]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_version]', 'Neutron_config[DEFAULT/use_ssl]', 'Neutron_config[DEFAULT/ssl_cert_file]', 'Neutron_config[DEFAULT/ssl_key_file]', 'Neutron_config[DEFAULT/ssl_ca_file]', 'Neutron_config[DEFAULT/use_syslog]', 'Neutron_config[DEFAULT/syslog_log_facility]', 'Neutron_config[DEFAULT/use_syslog_rfc_format]'],
  key     => 'net.ipv4.neigh.default.gc_thresh2',
  name    => 'net.ipv4.neigh.default.gc_thresh2',
  require => 'Class[Sysctl::Base]',
  value   => '2048',
}

sysctl::value { 'net.ipv4.neigh.default.gc_thresh3':
  before  => ['Neutron_config[DEFAULT/verbose]', 'Neutron_config[DEFAULT/debug]', 'Neutron_config[DEFAULT/use_stderr]', 'Neutron_config[DEFAULT/bind_host]', 'Neutron_config[DEFAULT/bind_port]', 'Neutron_config[DEFAULT/auth_strategy]', 'Neutron_config[DEFAULT/core_plugin]', 'Neutron_config[DEFAULT/base_mac]', 'Neutron_config[DEFAULT/mac_generation_retries]', 'Neutron_config[DEFAULT/dhcp_lease_duration]', 'Neutron_config[DEFAULT/dhcp_agents_per_network]', 'Neutron_config[DEFAULT/dhcp_agent_notification]', 'Neutron_config[DEFAULT/advertise_mtu]', 'Neutron_config[DEFAULT/allow_bulk]', 'Neutron_config[DEFAULT/allow_pagination]', 'Neutron_config[DEFAULT/allow_sorting]', 'Neutron_config[DEFAULT/allow_overlapping_ips]', 'Neutron_config[DEFAULT/control_exchange]', 'Neutron_config[DEFAULT/rpc_backend]', 'Neutron_config[DEFAULT/api_extensions_path]', 'Neutron_config[DEFAULT/state_path]', 'Neutron_config[DEFAULT/lock_path]', 'Neutron_config[DEFAULT/rpc_response_timeout]', 'Neutron_config[agent/root_helper]', 'Neutron_config[agent/report_interval]', 'Neutron_config[DEFAULT/log_dir]', 'Neutron_config[DEFAULT/log_file]', 'Neutron_config[DEFAULT/network_device_mtu]', 'Neutron_config[DEFAULT/service_plugins]', 'Neutron_config[DEFAULT/memcached_servers]', 'Neutron_config[oslo_messaging_rabbit/rabbit_hosts]', 'Neutron_config[oslo_messaging_rabbit/rabbit_ha_queues]', 'Neutron_config[oslo_messaging_rabbit/rabbit_userid]', 'Neutron_config[oslo_messaging_rabbit/rabbit_password]', 'Neutron_config[oslo_messaging_rabbit/rabbit_virtual_host]', 'Neutron_config[oslo_messaging_rabbit/heartbeat_timeout_threshold]', 'Neutron_config[oslo_messaging_rabbit/heartbeat_rate]', 'Neutron_config[oslo_messaging_rabbit/rabbit_use_ssl]', 'Neutron_config[oslo_messaging_rabbit/kombu_reconnect_delay]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_ca_certs]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_certfile]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_keyfile]', 'Neutron_config[oslo_messaging_rabbit/kombu_ssl_version]', 'Neutron_config[DEFAULT/use_ssl]', 'Neutron_config[DEFAULT/ssl_cert_file]', 'Neutron_config[DEFAULT/ssl_key_file]', 'Neutron_config[DEFAULT/ssl_ca_file]', 'Neutron_config[DEFAULT/use_syslog]', 'Neutron_config[DEFAULT/syslog_log_facility]', 'Neutron_config[DEFAULT/use_syslog_rfc_format]'],
  key     => 'net.ipv4.neigh.default.gc_thresh3',
  name    => 'net.ipv4.neigh.default.gc_thresh3',
  require => 'Class[Sysctl::Base]',
  value   => '4096',
}

sysctl { 'net.ipv4.ip_forward':
  before => 'Sysctl_runtime[net.ipv4.ip_forward]',
  name   => 'net.ipv4.ip_forward',
  val    => '1',
}

sysctl { 'net.ipv4.neigh.default.gc_thresh1':
  before => 'Sysctl_runtime[net.ipv4.neigh.default.gc_thresh1]',
  name   => 'net.ipv4.neigh.default.gc_thresh1',
  val    => '1024',
}

sysctl { 'net.ipv4.neigh.default.gc_thresh2':
  before => 'Sysctl_runtime[net.ipv4.neigh.default.gc_thresh2]',
  name   => 'net.ipv4.neigh.default.gc_thresh2',
  val    => '2048',
}

sysctl { 'net.ipv4.neigh.default.gc_thresh3':
  before => 'Sysctl_runtime[net.ipv4.neigh.default.gc_thresh3]',
  name   => 'net.ipv4.neigh.default.gc_thresh3',
  val    => '4096',
}

sysctl_runtime { 'net.ipv4.ip_forward':
  name => 'net.ipv4.ip_forward',
  val  => '1',
}

sysctl_runtime { 'net.ipv4.neigh.default.gc_thresh1':
  name => 'net.ipv4.neigh.default.gc_thresh1',
  val  => '1024',
}

sysctl_runtime { 'net.ipv4.neigh.default.gc_thresh2':
  name => 'net.ipv4.neigh.default.gc_thresh2',
  val  => '2048',
}

sysctl_runtime { 'net.ipv4.neigh.default.gc_thresh3':
  name => 'net.ipv4.neigh.default.gc_thresh3',
  val  => '4096',
}

