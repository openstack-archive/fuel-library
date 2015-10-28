ceilometer_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'false',
}

ceilometer_config { 'DEFAULT/http_timeout':
  name   => 'DEFAULT/http_timeout',
  notify => 'Service[ceilometer-agent-compute]',
  value  => '600',
}

ceilometer_config { 'DEFAULT/log_dir':
  name   => 'DEFAULT/log_dir',
  notify => 'Service[ceilometer-agent-compute]',
  value  => '/var/log/ceilometer',
}

ceilometer_config { 'DEFAULT/memcached_servers':
  ensure => 'absent',
  name   => 'DEFAULT/memcached_servers',
  notify => 'Service[ceilometer-agent-compute]',
}

ceilometer_config { 'DEFAULT/notification_topics':
  name   => 'DEFAULT/notification_topics',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'notifications',
}

ceilometer_config { 'DEFAULT/rpc_backend':
  name   => 'DEFAULT/rpc_backend',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'rabbit',
}

ceilometer_config { 'DEFAULT/syslog_log_facility':
  name   => 'DEFAULT/syslog_log_facility',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'LOG_LOCAL0',
}

ceilometer_config { 'DEFAULT/use_stderr':
  name   => 'DEFAULT/use_stderr',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'false',
}

ceilometer_config { 'DEFAULT/use_syslog':
  name   => 'DEFAULT/use_syslog',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'true',
}

ceilometer_config { 'DEFAULT/use_syslog_rfc_format':
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'true',
}

ceilometer_config { 'DEFAULT/verbose':
  name   => 'DEFAULT/verbose',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'true',
}

ceilometer_config { 'database/alarm_history_time_to_live':
  name   => 'database/alarm_history_time_to_live',
  notify => 'Service[ceilometer-agent-compute]',
  value  => '-1',
}

ceilometer_config { 'database/event_time_to_live':
  name   => 'database/event_time_to_live',
  notify => 'Service[ceilometer-agent-compute]',
  value  => '604800',
}

ceilometer_config { 'database/metering_time_to_live':
  name   => 'database/metering_time_to_live',
  notify => 'Service[ceilometer-agent-compute]',
  value  => '604800',
}

ceilometer_config { 'oslo_messaging_rabbit/heartbeat_rate':
  name   => 'oslo_messaging_rabbit/heartbeat_rate',
  notify => 'Service[ceilometer-agent-compute]',
  value  => '2',
}

ceilometer_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold':
  name   => 'oslo_messaging_rabbit/heartbeat_timeout_threshold',
  notify => 'Service[ceilometer-agent-compute]',
  value  => '0',
}

ceilometer_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_ca_certs',
  notify => 'Service[ceilometer-agent-compute]',
}

ceilometer_config { 'oslo_messaging_rabbit/kombu_ssl_certfile':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_certfile',
  notify => 'Service[ceilometer-agent-compute]',
}

ceilometer_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_keyfile',
  notify => 'Service[ceilometer-agent-compute]',
}

ceilometer_config { 'oslo_messaging_rabbit/kombu_ssl_version':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_version',
  notify => 'Service[ceilometer-agent-compute]',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  name   => 'oslo_messaging_rabbit/rabbit_ha_queues',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'false',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_host':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/rabbit_host',
  notify => 'Service[ceilometer-agent-compute]',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_hosts':
  name   => 'oslo_messaging_rabbit/rabbit_hosts',
  notify => 'Service[ceilometer-agent-compute]',
  value  => '192.168.0.3:5673',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_password':
  name   => 'oslo_messaging_rabbit/rabbit_password',
  notify => 'Service[ceilometer-agent-compute]',
  secret => 'true',
  value  => '1GXPbTgb',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_port':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/rabbit_port',
  notify => 'Service[ceilometer-agent-compute]',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_use_ssl':
  name   => 'oslo_messaging_rabbit/rabbit_use_ssl',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'false',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_userid':
  name   => 'oslo_messaging_rabbit/rabbit_userid',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'nova',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_virtual_host':
  name   => 'oslo_messaging_rabbit/rabbit_virtual_host',
  notify => 'Service[ceilometer-agent-compute]',
  value  => '/',
}

ceilometer_config { 'publisher/metering_secret':
  name   => 'publisher/metering_secret',
  notify => 'Service[ceilometer-agent-compute]',
  secret => 'true',
  value  => 'tHq2rcoq',
}

ceilometer_config { 'service_credentials/os_auth_url':
  name   => 'service_credentials/os_auth_url',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'http://192.168.0.7:5000/v2.0',
}

ceilometer_config { 'service_credentials/os_cacert':
  ensure => 'absent',
  name   => 'service_credentials/os_cacert',
  notify => 'Service[ceilometer-agent-compute]',
}

ceilometer_config { 'service_credentials/os_endpoint_type':
  before => 'Service[ceilometer-agent-compute]',
  name   => 'service_credentials/os_endpoint_type',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'internalURL',
}

ceilometer_config { 'service_credentials/os_password':
  name   => 'service_credentials/os_password',
  notify => 'Service[ceilometer-agent-compute]',
  secret => 'true',
  value  => 'WBfBSo6U',
}

ceilometer_config { 'service_credentials/os_region_name':
  name   => 'service_credentials/os_region_name',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'RegionOne',
}

ceilometer_config { 'service_credentials/os_tenant_name':
  name   => 'service_credentials/os_tenant_name',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'services',
}

ceilometer_config { 'service_credentials/os_username':
  name   => 'service_credentials/os_username',
  notify => 'Service[ceilometer-agent-compute]',
  value  => 'ceilometer',
}

class { 'Ceilometer::Agent::Auth':
  auth_password    => 'WBfBSo6U',
  auth_region      => 'RegionOne',
  auth_tenant_name => 'services',
  auth_url         => 'http://192.168.0.7:5000/v2.0',
  auth_user        => 'ceilometer',
  name             => 'Ceilometer::Agent::Auth',
}

class { 'Ceilometer::Agent::Compute':
  enabled        => 'true',
  manage_service => 'true',
  name           => 'Ceilometer::Agent::Compute',
  package_ensure => 'present',
}

class { 'Ceilometer::Client':
  ensure => 'present',
  name   => 'Ceilometer::Client',
}

class { 'Ceilometer::Params':
  name => 'Ceilometer::Params',
}

class { 'Ceilometer':
  alarm_history_time_to_live         => '-1',
  debug                              => 'false',
  event_time_to_live                 => '604800',
  http_timeout                       => '600',
  kombu_ssl_version                  => 'TLSv1',
  log_dir                            => '/var/log/ceilometer',
  log_facility                       => 'LOG_LOCAL0',
  metering_secret                    => 'tHq2rcoq',
  metering_time_to_live              => '604800',
  name                               => 'Ceilometer',
  notification_topics                => 'notifications',
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
  rabbit_host                        => '127.0.0.1',
  rabbit_hosts                       => '192.168.0.3:5673',
  rabbit_password                    => '1GXPbTgb',
  rabbit_port                        => '5672',
  rabbit_use_ssl                     => 'false',
  rabbit_userid                      => 'nova',
  rabbit_virtual_host                => '/',
  rpc_backend                        => 'rabbit',
  use_stderr                         => 'false',
  use_syslog                         => 'true',
  verbose                            => 'true',
}

class { 'Nova::Params':
  name => 'Nova::Params',
}

class { 'Openstack::Ceilometer':
  amqp_hosts            => '192.168.0.3:5673',
  amqp_password         => '1GXPbTgb',
  amqp_user             => 'nova',
  db_dbname             => 'ceilometer',
  db_host               => 'localhost',
  db_password           => 'ceilometer_pass',
  db_type               => 'mysql',
  db_user               => 'ceilometer',
  debug                 => 'false',
  event_time_to_live    => '604800',
  ext_mongo             => 'false',
  ha_mode               => 'false',
  host                  => '0.0.0.0',
  http_timeout          => '600',
  keystone_host         => '192.168.0.7',
  keystone_password     => 'WBfBSo6U',
  keystone_region       => 'RegionOne',
  keystone_tenant       => 'services',
  keystone_user         => 'ceilometer',
  metering_secret       => 'tHq2rcoq',
  metering_time_to_live => '604800',
  name                  => 'Openstack::Ceilometer',
  on_compute            => 'true',
  on_controller         => 'false',
  os_endpoint_type      => 'internalURL',
  port                  => '8777',
  rabbit_ha_queues      => 'false',
  swift_rados_backend   => 'false',
  syslog_log_facility   => 'LOG_LOCAL0',
  use_stderr            => 'false',
  use_syslog            => 'true',
  verbose               => 'true',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

group { 'ceilometer':
  name    => 'ceilometer',
  require => 'Package[ceilometer-common]',
}

notify { 'Module openstack cannot notify service ceilometer-alarm-evaluator on packages update':
  name => 'Module openstack cannot notify service ceilometer-alarm-evaluator on packages update',
}

package { 'ceilometer-agent-compute':
  ensure => 'present',
  before => 'Service[ceilometer-agent-compute]',
  name   => 'ceilometer-agent-compute',
  tag    => ['openstack', 'ceilometer-package'],
}

package { 'ceilometer-common':
  ensure => 'present',
  before => 'Service[ceilometer-agent-compute]',
  name   => 'ceilometer-common',
  tag    => ['openstack', 'ceilometer-package'],
}

package { 'python-ceilometerclient':
  ensure => 'present',
  name   => 'python-ceilometerclient',
  tag    => 'openstack',
}

service { 'ceilometer-agent-compute':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'ceilometer-agent-compute',
  tag        => 'ceilometer-service',
}

service { 'nova-compute':
  ensure => 'running',
  name   => 'nova-compute',
}

stage { 'main':
  name => 'main',
}

user { 'ceilometer':
  gid     => 'ceilometer',
  groups  => ['nova', 'libvirtd'],
  name    => 'ceilometer',
  require => 'Package[ceilometer-common]',
  system  => 'true',
}

