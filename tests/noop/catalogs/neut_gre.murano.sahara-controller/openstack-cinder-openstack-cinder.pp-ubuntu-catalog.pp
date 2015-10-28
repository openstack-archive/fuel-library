anchor { 'cinder-start':
  name => 'cinder-start',
}

cinder_api_paste_ini { 'filter:authtoken/admin_password':
  name   => 'filter:authtoken/admin_password',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
  secret => 'true',
  value  => 'O2st17AP',
}

cinder_api_paste_ini { 'filter:authtoken/admin_tenant_name':
  name   => 'filter:authtoken/admin_tenant_name',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
  value  => 'services',
}

cinder_api_paste_ini { 'filter:authtoken/admin_user':
  name   => 'filter:authtoken/admin_user',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
  value  => 'cinder',
}

cinder_api_paste_ini { 'filter:authtoken/auth_admin_prefix':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_admin_prefix',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
}

cinder_api_paste_ini { 'filter:authtoken/auth_host':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_host',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
}

cinder_api_paste_ini { 'filter:authtoken/auth_port':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_port',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
}

cinder_api_paste_ini { 'filter:authtoken/auth_protocol':
  ensure => 'absent',
  name   => 'filter:authtoken/auth_protocol',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
}

cinder_api_paste_ini { 'filter:authtoken/auth_uri':
  name   => 'filter:authtoken/auth_uri',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
  value  => 'http://192.168.0.2:5000/',
}

cinder_api_paste_ini { 'filter:authtoken/identity_uri':
  name   => 'filter:authtoken/identity_uri',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
  value  => 'http://192.168.0.2:5000/',
}

cinder_api_paste_ini { 'filter:authtoken/service_host':
  ensure => 'absent',
  name   => 'filter:authtoken/service_host',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
}

cinder_api_paste_ini { 'filter:authtoken/service_port':
  ensure => 'absent',
  name   => 'filter:authtoken/service_port',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
}

cinder_api_paste_ini { 'filter:authtoken/service_protocol':
  ensure => 'absent',
  name   => 'filter:authtoken/service_protocol',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
}

cinder_api_paste_ini { 'filter:ratelimit/limits':
  name   => 'filter:ratelimit/limits',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
  value  => {'DELETE' => '100000', 'GET' => '100000', 'POST' => '100000', 'POST_SERVERS' => '100000', 'PUT' => '100000'},
}

cinder_api_paste_ini { 'filter:ratelimit/paste.filter_factory':
  name   => 'filter:ratelimit/paste.filter_factory',
  notify => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
  value  => 'cinder.api.v1.limits:RateLimitingMiddleware.factory',
}

cinder_config { 'DEFAULT/amqp_durable_queues':
  name   => 'DEFAULT/amqp_durable_queues',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'false',
}

cinder_config { 'DEFAULT/api_paste_config':
  name   => 'DEFAULT/api_paste_config',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '/etc/cinder/api-paste.ini',
}

cinder_config { 'DEFAULT/auth_strategy':
  name   => 'DEFAULT/auth_strategy',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'keystone',
}

cinder_config { 'DEFAULT/control_exchange':
  name   => 'DEFAULT/control_exchange',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'cinder',
}

cinder_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'false',
}

cinder_config { 'DEFAULT/default_availability_zone':
  name   => 'DEFAULT/default_availability_zone',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'nova',
}

cinder_config { 'DEFAULT/default_volume_type':
  name   => 'DEFAULT/default_volume_type',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'DEFAULT/enable_v1_api':
  name   => 'DEFAULT/enable_v1_api',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'true',
}

cinder_config { 'DEFAULT/enable_v2_api':
  name   => 'DEFAULT/enable_v2_api',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'true',
}

cinder_config { 'DEFAULT/glance_api_insecure':
  name   => 'DEFAULT/glance_api_insecure',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'false',
}

cinder_config { 'DEFAULT/glance_api_servers':
  name   => 'DEFAULT/glance_api_servers',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '192.168.0.2:9292',
}

cinder_config { 'DEFAULT/glance_api_ssl_compression':
  name   => 'DEFAULT/glance_api_ssl_compression',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'false',
}

cinder_config { 'DEFAULT/glance_api_version':
  name   => 'DEFAULT/glance_api_version',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '2',
}

cinder_config { 'DEFAULT/glance_num_retries':
  name   => 'DEFAULT/glance_num_retries',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '0',
}

cinder_config { 'DEFAULT/glance_request_timeout':
  name   => 'DEFAULT/glance_request_timeout',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
}

cinder_config { 'DEFAULT/kombu_reconnect_delay':
  name   => 'DEFAULT/kombu_reconnect_delay',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '5.0',
}

cinder_config { 'DEFAULT/lock_path':
  name   => 'DEFAULT/lock_path',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '/var/lock/cinder',
}

cinder_config { 'DEFAULT/log_dir':
  name   => 'DEFAULT/log_dir',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'DEFAULT/nova_catalog_admin_info':
  name   => 'DEFAULT/nova_catalog_admin_info',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'compute:nova:adminURL',
}

cinder_config { 'DEFAULT/nova_catalog_info':
  name   => 'DEFAULT/nova_catalog_info',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'compute:nova:internalURL',
}

cinder_config { 'DEFAULT/os_privileged_user_auth_url':
  name   => 'DEFAULT/os_privileged_user_auth_url',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'http://192.168.0.2:5000/',
}

cinder_config { 'DEFAULT/os_privileged_user_name':
  name   => 'DEFAULT/os_privileged_user_name',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'cinder',
}

cinder_config { 'DEFAULT/os_privileged_user_password':
  name   => 'DEFAULT/os_privileged_user_password',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'O2st17AP',
}

cinder_config { 'DEFAULT/os_privileged_user_tenant':
  name   => 'DEFAULT/os_privileged_user_tenant',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'services',
}

cinder_config { 'DEFAULT/os_region_name':
  name   => 'DEFAULT/os_region_name',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'RegionOne',
}

cinder_config { 'DEFAULT/osapi_volume_listen':
  name   => 'DEFAULT/osapi_volume_listen',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '192.168.0.3',
}

cinder_config { 'DEFAULT/osapi_volume_workers':
  name   => 'DEFAULT/osapi_volume_workers',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '4',
}

cinder_config { 'DEFAULT/rpc_backend':
  name   => 'DEFAULT/rpc_backend',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'cinder.openstack.common.rpc.impl_kombu',
}

cinder_config { 'DEFAULT/scheduler_driver':
  name   => 'DEFAULT/scheduler_driver',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'DEFAULT/ssl_ca_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_ca_file',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
}

cinder_config { 'DEFAULT/ssl_cert_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_cert_file',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
}

cinder_config { 'DEFAULT/ssl_key_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_key_file',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
}

cinder_config { 'DEFAULT/storage_availability_zone':
  name   => 'DEFAULT/storage_availability_zone',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'nova',
}

cinder_config { 'DEFAULT/syslog_log_facility':
  name   => 'DEFAULT/syslog_log_facility',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'LOG_LOCAL3',
}

cinder_config { 'DEFAULT/use_stderr':
  name   => 'DEFAULT/use_stderr',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'false',
}

cinder_config { 'DEFAULT/use_syslog':
  name   => 'DEFAULT/use_syslog',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'true',
}

cinder_config { 'DEFAULT/use_syslog_rfc_format':
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'true',
}

cinder_config { 'DEFAULT/verbose':
  name   => 'DEFAULT/verbose',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'true',
}

cinder_config { 'database/connection':
  name   => 'database/connection',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  secret => 'true',
  value  => 'mysql://cinder:71kNkN9U@192.168.0.2/cinder?charset=utf8&read_timeout=60',
}

cinder_config { 'database/idle_timeout':
  name   => 'database/idle_timeout',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '3600',
}

cinder_config { 'database/max_overflow':
  name   => 'database/max_overflow',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '20',
}

cinder_config { 'database/max_pool_size':
  name   => 'database/max_pool_size',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '20',
}

cinder_config { 'database/max_retries':
  name   => 'database/max_retries',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '-1',
}

cinder_config { 'database/min_pool_size':
  name   => 'database/min_pool_size',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'database/retry_interval':
  name   => 'database/retry_interval',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'keystone_authtoken/admin_password':
  name   => 'keystone_authtoken/admin_password',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'O2st17AP',
}

cinder_config { 'keystone_authtoken/admin_tenant_name':
  name   => 'keystone_authtoken/admin_tenant_name',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'services',
}

cinder_config { 'keystone_authtoken/admin_user':
  name   => 'keystone_authtoken/admin_user',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'cinder',
}

cinder_config { 'keystone_authtoken/auth_uri':
  name   => 'keystone_authtoken/auth_uri',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'http://192.168.0.2:5000/',
}

cinder_config { 'keystone_authtoken/identity_uri':
  name   => 'keystone_authtoken/identity_uri',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'http://192.168.0.2:5000/',
}

cinder_config { 'keystone_authtoken/signing_dir':
  name   => 'keystone_authtoken/signing_dir',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '/tmp/keystone-signing-cinder',
}

cinder_config { 'keystone_authtoken/signing_dirname':
  name   => 'keystone_authtoken/signing_dirname',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '/tmp/keystone-signing-cinder',
}

cinder_config { 'oslo_messaging_rabbit/heartbeat_rate':
  name   => 'oslo_messaging_rabbit/heartbeat_rate',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '2',
}

cinder_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold':
  name   => 'oslo_messaging_rabbit/heartbeat_timeout_threshold',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '0',
}

cinder_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs':
  name   => 'oslo_messaging_rabbit/kombu_ssl_ca_certs',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'oslo_messaging_rabbit/kombu_ssl_certfile':
  name   => 'oslo_messaging_rabbit/kombu_ssl_certfile',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile':
  name   => 'oslo_messaging_rabbit/kombu_ssl_keyfile',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'oslo_messaging_rabbit/kombu_ssl_version':
  name   => 'oslo_messaging_rabbit/kombu_ssl_version',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  before => ['Service[cinder-api]', 'Service[cinder-scheduler]'],
  name   => 'oslo_messaging_rabbit/rabbit_ha_queues',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'true',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_host':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/rabbit_host',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
}

cinder_config { 'oslo_messaging_rabbit/rabbit_hosts':
  name   => 'oslo_messaging_rabbit/rabbit_hosts',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '192.168.0.3:5673, 192.168.0.2:5673, 192.168.0.4:5673',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_password':
  name   => 'oslo_messaging_rabbit/rabbit_password',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  secret => 'true',
  value  => 'c7fQJeSe',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_port':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/rabbit_port',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
}

cinder_config { 'oslo_messaging_rabbit/rabbit_use_ssl':
  name   => 'oslo_messaging_rabbit/rabbit_use_ssl',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'false',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_userid':
  name   => 'oslo_messaging_rabbit/rabbit_userid',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => 'nova',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_virtual_host':
  name   => 'oslo_messaging_rabbit/rabbit_virtual_host',
  notify => ['Service[cinder-api]', 'Exec[cinder-manage db_sync]', 'Service[cinder-scheduler]'],
  value  => '/',
}

class { 'Cinder::Api':
  auth_uri                    => 'http://192.168.0.2:5000/',
  bind_host                   => '192.168.0.3',
  default_volume_type         => '<SERVICE DEFAULT>',
  enabled                     => 'true',
  identity_uri                => 'http://192.168.0.2:5000/',
  keystone_auth_admin_prefix  => 'false',
  keystone_auth_host          => 'localhost',
  keystone_auth_port          => '35357',
  keystone_auth_protocol      => 'http',
  keystone_auth_uri           => 'false',
  keystone_enabled            => 'true',
  keystone_password           => 'O2st17AP',
  keystone_tenant             => 'services',
  keystone_user               => 'cinder',
  manage_service              => 'true',
  name                        => 'Cinder::Api',
  nova_catalog_admin_info     => 'compute:nova:adminURL',
  nova_catalog_info           => 'compute:nova:internalURL',
  os_privileged_user_auth_url => 'http://192.168.0.2:5000/',
  os_privileged_user_name     => 'cinder',
  os_privileged_user_password => 'O2st17AP',
  os_privileged_user_tenant   => 'services',
  os_region_name              => 'RegionOne',
  package_ensure              => 'installed',
  privileged_user             => 'true',
  ratelimits                  => {'DELETE' => '100000', 'GET' => '100000', 'POST' => '100000', 'POST_SERVERS' => '100000', 'PUT' => '100000'},
  ratelimits_factory          => 'cinder.api.v1.limits:RateLimitingMiddleware.factory',
  service_port                => '5000',
  service_workers             => '4',
  sync_db                     => 'true',
  validate                    => 'false',
  validation_options          => {},
}

class { 'Cinder::Db::Sync':
  name => 'Cinder::Db::Sync',
}

class { 'Cinder::Db':
  database_connection     => 'sqlite:////var/lib/cinder/cinder.sqlite',
  database_idle_timeout   => '<SERVICE DEFAULT>',
  database_max_overflow   => '<SERVICE DEFAULT>',
  database_max_pool_size  => '<SERVICE DEFAULT>',
  database_max_retries    => '<SERVICE DEFAULT>',
  database_min_pool_size  => '<SERVICE DEFAULT>',
  database_retry_interval => '<SERVICE DEFAULT>',
  name                    => 'Cinder::Db',
  require                 => ['Class[Mysql::Bindings]', 'Class[Mysql::Bindings::Python]'],
}

class { 'Cinder::Glance':
  glance_api_insecure        => 'false',
  glance_api_servers         => '192.168.0.2:9292',
  glance_api_ssl_compression => 'false',
  glance_api_version         => '2',
  glance_num_retries         => '0',
  name                       => 'Cinder::Glance',
}

class { 'Cinder::Params':
  name => 'Cinder::Params',
}

class { 'Cinder::Policy':
  name        => 'Cinder::Policy',
  notify      => 'Service[cinder-api]',
  policies    => {},
  policy_path => '/etc/cinder/policy.json',
}

class { 'Cinder::Scheduler':
  enabled          => 'true',
  manage_service   => 'true',
  name             => 'Cinder::Scheduler',
  package_ensure   => 'installed',
  scheduler_driver => '<SERVICE DEFAULT>',
}

class { 'Cinder':
  amqp_durable_queues                => 'false',
  api_paste_config                   => '/etc/cinder/api-paste.ini',
  ca_file                            => '<SERVICE DEFAULT>',
  cert_file                          => 'false',
  control_exchange                   => 'cinder',
  database_connection                => 'mysql://cinder:71kNkN9U@192.168.0.2/cinder?charset=utf8&read_timeout=60',
  database_idle_timeout              => '3600',
  database_max_overflow              => '20',
  database_max_pool_size             => '20',
  database_max_retries               => '-1',
  debug                              => 'false',
  default_availability_zone          => 'false',
  enable_v1_api                      => 'true',
  enable_v2_api                      => 'true',
  key_file                           => 'false',
  kombu_ssl_ca_certs                 => '<SERVICE DEFAULT>',
  kombu_ssl_certfile                 => '<SERVICE DEFAULT>',
  kombu_ssl_keyfile                  => '<SERVICE DEFAULT>',
  kombu_ssl_version                  => '<SERVICE DEFAULT>',
  lock_path                          => '/var/lock/cinder',
  log_dir                            => '<SERVICE DEFAULT>',
  log_facility                       => 'LOG_LOCAL3',
  name                               => 'Cinder',
  package_ensure                     => 'installed',
  qpid_heartbeat                     => '60',
  qpid_hostname                      => 'localhost',
  qpid_password                      => 'false',
  qpid_port                          => '5672',
  qpid_protocol                      => 'tcp',
  qpid_reconnect                     => 'true',
  qpid_reconnect_interval            => '0',
  qpid_reconnect_interval_max        => '0',
  qpid_reconnect_interval_min        => '0',
  qpid_reconnect_limit               => '0',
  qpid_reconnect_timeout             => '0',
  qpid_sasl_mechanisms               => 'false',
  qpid_tcp_nodelay                   => 'true',
  qpid_username                      => 'guest',
  rabbit_heartbeat_rate              => '2',
  rabbit_heartbeat_timeout_threshold => '0',
  rabbit_host                        => '127.0.0.1',
  rabbit_hosts                       => ['192.168.0.3:5673', ' 192.168.0.2:5673', ' 192.168.0.4:5673'],
  rabbit_password                    => 'c7fQJeSe',
  rabbit_port                        => '5672',
  rabbit_use_ssl                     => 'false',
  rabbit_userid                      => 'nova',
  rabbit_virtual_host                => '/',
  rpc_backend                        => 'cinder.openstack.common.rpc.impl_kombu',
  storage_availability_zone          => 'nova',
  use_ssl                            => 'false',
  use_stderr                         => 'false',
  use_syslog                         => 'true',
  verbose                            => 'true',
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

class { 'Openstack::Cinder':
  amqp_hosts           => '192.168.0.3:5673, 192.168.0.2:5673, 192.168.0.4:5673',
  amqp_password        => 'c7fQJeSe',
  amqp_user            => 'nova',
  auth_host            => '192.168.0.2',
  auth_uri             => 'http://192.168.0.2:5000/',
  bind_host            => '192.168.0.3',
  ceilometer           => 'false',
  cinder_rate_limits   => {'DELETE' => '100000', 'GET' => '100000', 'POST' => '100000', 'POST_SERVERS' => '100000', 'PUT' => '100000'},
  cinder_user_password => 'O2st17AP',
  debug                => 'false',
  enable_volumes       => 'true',
  enabled              => 'true',
  glance_api_servers   => '192.168.0.2:9292',
  identity_uri         => 'http://192.168.0.2:5000/',
  idle_timeout         => '3600',
  iscsi_bind_host      => '192.168.1.3',
  iser                 => 'false',
  keystone_enabled     => 'true',
  keystone_tenant      => 'services',
  keystone_user        => 'cinder',
  manage_volumes       => 'false',
  max_overflow         => '20',
  max_pool_size        => '20',
  max_retries          => '-1',
  name                 => 'Openstack::Cinder',
  purge_cinder_config  => 'true',
  queue_provider       => 'rabbitmq',
  rabbit_ha_queues     => 'true',
  rbd_pool             => 'volumes',
  rbd_secret_uuid      => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
  rbd_user             => 'volumes',
  region               => 'RegionOne',
  service_workers      => '4',
  sql_connection       => 'mysql://cinder:71kNkN9U@192.168.0.2/cinder?charset=utf8&read_timeout=60',
  syslog_log_facility  => 'LOG_LOCAL3',
  use_stderr           => 'false',
  use_syslog           => 'true',
  verbose              => 'true',
  vmware_host_ip       => '10.10.10.10',
  vmware_host_password => 'password',
  vmware_host_username => 'administrator@vsphere.local',
  volume_group         => 'cinder',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'cinder-manage db_sync':
  command     => 'cinder-manage db sync',
  logoutput   => 'on_failure',
  notify      => ['Service[cinder-api]', 'Service[cinder-scheduler]', 'Service[cinder-scheduler]'],
  path        => '/usr/bin',
  refreshonly => 'true',
  user        => 'cinder',
}

exec { 'remove_cinder-api_override':
  before  => ['Service[cinder-api]', 'Service[cinder-api]'],
  command => 'rm -f /etc/init/cinder-api.override',
  onlyif  => 'test -f /etc/init/cinder-api.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_cinder-backup_override':
  command => 'rm -f /etc/init/cinder-backup.override',
  onlyif  => 'test -f /etc/init/cinder-backup.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_cinder-scheduler_override':
  before  => ['Service[cinder-scheduler]', 'Service[cinder-scheduler]'],
  command => 'rm -f /etc/init/cinder-scheduler.override',
  onlyif  => 'test -f /etc/init/cinder-scheduler.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { 'create_cinder-api_override':
  ensure  => 'present',
  before  => ['Package[cinder-api]', 'Package[cinder-api]', 'Exec[remove_cinder-api_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/cinder-api.override',
}

file { 'create_cinder-backup_override':
  ensure  => 'present',
  before  => 'Exec[remove_cinder-backup_override]',
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/cinder-backup.override',
}

file { 'create_cinder-scheduler_override':
  ensure  => 'present',
  before  => ['Package[cinder-scheduler]', 'Package[cinder-scheduler]', 'Exec[remove_cinder-scheduler_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/cinder-scheduler.override',
}

package { 'cinder-api':
  ensure => 'installed',
  before => ['Class[Cinder::Policy]', 'Service[cinder-api]', 'Exec[remove_cinder-api_override]', 'Exec[remove_cinder-api_override]'],
  name   => 'cinder-api',
  notify => ['Exec[cinder-manage db_sync]', 'Exec[cinder-manage db_sync]'],
  tag    => ['openstack', 'cinder-package'],
}

package { 'cinder-scheduler':
  ensure => 'installed',
  before => ['Service[cinder-scheduler]', 'Exec[remove_cinder-scheduler_override]', 'Exec[remove_cinder-scheduler_override]'],
  name   => 'cinder-scheduler',
  notify => 'Exec[cinder-manage db_sync]',
  tag    => ['openstack', 'cinder-package'],
}

package { 'cinder':
  ensure  => 'installed',
  name    => 'cinder-common',
  notify  => 'Exec[cinder-manage db_sync]',
  require => 'Anchor[cinder-start]',
  tag     => ['openstack', 'cinder-package'],
}

package { 'python-mysqldb':
  ensure => 'present',
  name   => 'python-mysqldb',
}

service { 'cinder-api':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'cinder-api',
  require   => 'Package[cinder]',
  tag       => 'cinder-service',
}

service { 'cinder-scheduler':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'cinder-scheduler',
  require   => 'Package[cinder]',
  tag       => 'cinder-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'cinder-api':
  name         => 'cinder-api',
  package_name => 'cinder-api',
  service_name => 'cinder-api',
}

tweaks::ubuntu_service_override { 'cinder-backup':
  name         => 'cinder-backup',
  package_name => 'cinder-backup',
  service_name => 'cinder-backup',
}

tweaks::ubuntu_service_override { 'cinder-scheduler':
  name         => 'cinder-scheduler',
  package_name => 'cinder-scheduler',
  service_name => 'cinder-scheduler',
}

