class { 'Glance::Api':
  auth_admin_prefix        => 'false',
  auth_host                => '192.168.0.7',
  auth_port                => '35357',
  auth_protocol            => 'http',
  auth_type                => 'keystone',
  auth_uri                 => 'false',
  auth_url                 => 'http://192.168.0.7:5000/',
  backlog                  => '4096',
  before                   => 'Class[Glance::Cache::Pruner]',
  bind_host                => '192.168.0.3',
  bind_port                => '9292',
  ca_file                  => 'false',
  cert_file                => 'false',
  database_connection      => 'mysql://glance:385SUUrC@192.168.0.7/glance?read_timeout=60',
  database_idle_timeout    => '3600',
  debug                    => 'false',
  enabled                  => 'true',
  identity_uri             => 'false',
  image_cache_dir          => '/var/lib/glance/image-cache',
  key_file                 => 'false',
  keystone_password        => 'A9KgbnX6',
  keystone_tenant          => 'services',
  keystone_user            => 'glance',
  known_stores             => ['glance.store.rbd.Store', 'glance.store.http.Store'],
  log_dir                  => '/var/log/glance',
  log_facility             => 'LOG_LOCAL2',
  log_file                 => '/var/log/glance/api.log',
  manage_service           => 'true',
  name                     => 'Glance::Api',
  os_region_name           => 'RegionOne',
  package_ensure           => 'present',
  pipeline                 => 'keystone',
  purge_config             => 'false',
  registry_client_protocol => 'http',
  registry_host            => '192.168.0.7',
  registry_port            => '9191',
  require                  => ['Class[Keystone::Python]', 'Class[Mysql::Bindings]', 'Class[Mysql::Bindings::Python]'],
  show_image_direct_url    => 'true',
  use_stderr               => 'false',
  use_syslog               => 'true',
  validate                 => 'false',
  validation_options       => {},
  verbose                  => 'true',
  workers                  => '4',
}

class { 'Glance::Backend::Rbd':
  name                  => 'Glance::Backend::Rbd',
  package_ensure        => 'present',
  rados_connect_timeout => '30',
  rbd_store_ceph_conf   => '/etc/ceph/ceph.conf',
  rbd_store_chunk_size  => '8',
  rbd_store_pool        => 'images',
  rbd_store_user        => 'images',
}

class { 'Glance::Cache::Cleaner':
  command_options => '',
  hour            => '0',
  minute          => '1',
  month           => '*',
  monthday        => '*',
  name            => 'Glance::Cache::Cleaner',
  weekday         => '*',
}

class { 'Glance::Cache::Pruner':
  before          => 'Class[Glance::Cache::Cleaner]',
  command_options => '',
  hour            => '*',
  minute          => '*/30',
  month           => '*',
  monthday        => '*',
  name            => 'Glance::Cache::Pruner',
  weekday         => '*',
}

class { 'Glance::Db::Sync':
  name => 'Glance::Db::Sync',
}

class { 'Glance::Notify::Rabbitmq':
  amqp_durable_queues                => 'false',
  kombu_ssl_version                  => 'TLSv1',
  name                               => 'Glance::Notify::Rabbitmq',
  notification_driver                => 'messaging',
  rabbit_durable_queues              => 'false',
  rabbit_heartbeat_rate              => '2',
  rabbit_heartbeat_timeout_threshold => '0',
  rabbit_host                        => 'localhost',
  rabbit_hosts                       => '192.168.0.3:5673',
  rabbit_notification_exchange       => 'glance',
  rabbit_notification_topic          => 'notifications',
  rabbit_password                    => '1GXPbTgb',
  rabbit_port                        => '5672',
  rabbit_use_ssl                     => 'false',
  rabbit_userid                      => 'nova',
  rabbit_virtual_host                => '/',
}

class { 'Glance::Params':
  name => 'Glance::Params',
}

class { 'Glance::Policy':
  name        => 'Glance::Policy',
  notify      => 'Service[glance-api]',
  policies    => {},
  policy_path => '/etc/glance/policy.json',
}

class { 'Glance::Registry':
  auth_admin_prefix     => 'false',
  auth_host             => '192.168.0.7',
  auth_port             => '35357',
  auth_protocol         => 'http',
  auth_type             => 'keystone',
  auth_uri              => 'false',
  bind_host             => '192.168.0.3',
  bind_port             => '9191',
  ca_file               => 'false',
  cert_file             => 'false',
  database_connection   => 'mysql://glance:385SUUrC@192.168.0.7/glance?read_timeout=60',
  database_idle_timeout => '3600',
  debug                 => 'false',
  enabled               => 'true',
  identity_uri          => 'false',
  key_file              => 'false',
  keystone_password     => 'A9KgbnX6',
  keystone_tenant       => 'services',
  keystone_user         => 'glance',
  log_dir               => '/var/log/glance',
  log_facility          => 'LOG_LOCAL2',
  log_file              => '/var/log/glance/registry.log',
  manage_service        => 'true',
  name                  => 'Glance::Registry',
  package_ensure        => 'present',
  pipeline              => 'keystone',
  purge_config          => 'false',
  require               => ['Class[Keystone::Python]', 'Class[Mysql::Bindings]', 'Class[Mysql::Bindings::Python]'],
  sync_db               => 'true',
  use_stderr            => 'false',
  use_syslog            => 'true',
  verbose               => 'true',
  workers               => '4',
}

class { 'Glance':
  name           => 'Glance',
  package_ensure => 'present',
}

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

class { 'Openstack::Glance':
  amqp_durable_queues            => 'false',
  auth_uri                       => 'http://192.168.0.7:5000/',
  bind_host                      => '192.168.0.3',
  ceilometer                     => 'true',
  db_host                        => '192.168.0.7',
  db_type                        => 'mysql',
  debug                          => 'false',
  enabled                        => 'true',
  glance_backend                 => 'ceph',
  glance_db_dbname               => 'glance',
  glance_db_password             => '385SUUrC',
  glance_db_user                 => 'glance',
  glance_image_cache_max_size    => '0',
  glance_tenant                  => 'services',
  glance_user                    => 'glance',
  glance_user_password           => 'A9KgbnX6',
  glance_vcenter_api_retry_count => '20',
  idle_timeout                   => '3600',
  keystone_host                  => '192.168.0.7',
  known_stores                   => ['glance.store.rbd.Store', 'glance.store.http.Store'],
  max_overflow                   => '20',
  max_pool_size                  => '20',
  max_retries                    => '-1',
  name                           => 'Openstack::Glance',
  pipeline                       => 'keystone',
  rabbit_host                    => 'localhost',
  rabbit_hosts                   => '192.168.0.3:5673',
  rabbit_notification_exchange   => 'glance',
  rabbit_notification_topic      => 'notifications',
  rabbit_password                => '1GXPbTgb',
  rabbit_port                    => '5672',
  rabbit_use_ssl                 => 'false',
  rabbit_userid                  => 'nova',
  rabbit_virtual_host            => '/',
  rados_connect_timeout          => '30',
  rbd_store_pool                 => 'images',
  rbd_store_user                 => 'images',
  region                         => 'RegionOne',
  registry_host                  => '192.168.0.7',
  service_workers                => '4',
  show_image_direct_url          => 'true',
  swift_store_large_object_size  => '5120',
  syslog_log_facility            => 'LOG_LOCAL2',
  use_stderr                     => 'false',
  use_syslog                     => 'true',
  verbose                        => 'true',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cron { 'glance-cache-cleaner':
  command     => 'glance-cache-cleaner',
  environment => 'PATH=/bin:/usr/bin:/usr/sbin',
  hour        => '0',
  minute      => '1',
  month       => '*',
  monthday    => '*',
  name        => 'glance-cache-cleaner',
  require     => 'Package[glance-api]',
  user        => 'glance',
  weekday     => '*',
}

cron { 'glance-cache-pruner':
  command     => 'glance-cache-pruner',
  environment => 'PATH=/bin:/usr/bin:/usr/sbin',
  hour        => '*',
  minute      => '*/30',
  month       => '*',
  monthday    => '*',
  name        => 'glance-cache-pruner',
  require     => 'Package[glance-api]',
  user        => 'glance',
  weekday     => '*',
}

exec { 'glance-manage db_sync':
  command     => 'glance-manage --config-file=/etc/glance/glance-registry.conf db_sync',
  logoutput   => 'on_failure',
  notify      => ['Service[glance-api]', 'Service[glance-registry]'],
  path        => '/usr/bin',
  refreshonly => 'true',
  user        => 'glance',
}

exec { 'remove_glance-api_override':
  before  => ['Service[glance-api]', 'Service[glance-api]'],
  command => 'rm -f /etc/init/glance-api.override',
  onlyif  => 'test -f /etc/init/glance-api.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_glance-registry_override':
  before  => ['Service[glance-registry]', 'Service[glance-registry]'],
  command => 'rm -f /etc/init/glance-registry.override',
  onlyif  => 'test -f /etc/init/glance-registry.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/etc/glance/':
  ensure => 'directory',
  group  => 'root',
  mode   => '0770',
  owner  => 'glance',
  path   => '/etc/glance',
}

file { '/etc/glance/glance-api-paste.ini':
  ensure  => 'present',
  group   => 'glance',
  mode    => '0640',
  notify  => 'Service[glance-api]',
  owner   => 'glance',
  path    => '/etc/glance/glance-api-paste.ini',
  require => 'Class[Glance]',
}

file { '/etc/glance/glance-api.conf':
  ensure  => 'present',
  group   => 'glance',
  mode    => '0640',
  notify  => 'Service[glance-api]',
  owner   => 'glance',
  path    => '/etc/glance/glance-api.conf',
  require => 'Class[Glance]',
}

file { '/etc/glance/glance-cache.conf':
  ensure  => 'present',
  group   => 'glance',
  mode    => '0640',
  notify  => 'Service[glance-api]',
  owner   => 'glance',
  path    => '/etc/glance/glance-cache.conf',
  require => 'Class[Glance]',
}

file { '/etc/glance/glance-registry-paste.ini':
  ensure  => 'present',
  group   => 'glance',
  mode    => '0640',
  notify  => 'Service[glance-registry]',
  owner   => 'glance',
  path    => '/etc/glance/glance-registry-paste.ini',
  require => 'Class[Glance]',
}

file { '/etc/glance/glance-registry.conf':
  ensure  => 'present',
  group   => 'glance',
  mode    => '0640',
  notify  => 'Service[glance-registry]',
  owner   => 'glance',
  path    => '/etc/glance/glance-registry.conf',
  require => 'Class[Glance]',
}

file { 'create_glance-api_override':
  ensure  => 'present',
  before  => ['Package[glance-api]', 'Exec[remove_glance-api_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/glance-api.override',
}

file { 'create_glance-registry_override':
  ensure  => 'present',
  before  => ['Package[glance-registry]', 'Exec[remove_glance-registry_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/glance-registry.override',
}

glance_api_config { 'DEFAULT/amqp_durable_queues':
  name   => 'DEFAULT/amqp_durable_queues',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'false',
}

glance_api_config { 'DEFAULT/auth_region':
  name   => 'DEFAULT/auth_region',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'RegionOne',
}

glance_api_config { 'DEFAULT/backlog':
  name   => 'DEFAULT/backlog',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '4096',
}

glance_api_config { 'DEFAULT/bind_host':
  name   => 'DEFAULT/bind_host',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '192.168.0.3',
}

glance_api_config { 'DEFAULT/bind_port':
  name   => 'DEFAULT/bind_port',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '9292',
}

glance_api_config { 'DEFAULT/ca_file':
  ensure => 'absent',
  name   => 'DEFAULT/ca_file',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
}

glance_api_config { 'DEFAULT/cert_file':
  ensure => 'absent',
  name   => 'DEFAULT/cert_file',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
}

glance_api_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'false',
}

glance_api_config { 'DEFAULT/delayed_delete':
  name   => 'DEFAULT/delayed_delete',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'False',
}

glance_api_config { 'DEFAULT/image_cache_dir':
  name   => 'DEFAULT/image_cache_dir',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '/var/lib/glance/image-cache',
}

glance_api_config { 'DEFAULT/key_file':
  ensure => 'absent',
  name   => 'DEFAULT/key_file',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
}

glance_api_config { 'DEFAULT/log_dir':
  name   => 'DEFAULT/log_dir',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '/var/log/glance',
}

glance_api_config { 'DEFAULT/log_file':
  name   => 'DEFAULT/log_file',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '/var/log/glance/api.log',
}

glance_api_config { 'DEFAULT/notification_driver':
  name   => 'DEFAULT/notification_driver',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'messaging',
}

glance_api_config { 'DEFAULT/os_region_name':
  name   => 'DEFAULT/os_region_name',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'RegionOne',
}

glance_api_config { 'DEFAULT/registry_client_protocol':
  name   => 'DEFAULT/registry_client_protocol',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'http',
}

glance_api_config { 'DEFAULT/registry_host':
  name   => 'DEFAULT/registry_host',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '192.168.0.7',
}

glance_api_config { 'DEFAULT/registry_port':
  name   => 'DEFAULT/registry_port',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '9191',
}

glance_api_config { 'DEFAULT/scrub_time':
  name   => 'DEFAULT/scrub_time',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '43200',
}

glance_api_config { 'DEFAULT/scrubber_datadir':
  name   => 'DEFAULT/scrubber_datadir',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '/var/lib/glance/scrubber',
}

glance_api_config { 'DEFAULT/show_image_direct_url':
  name   => 'DEFAULT/show_image_direct_url',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_api_config { 'DEFAULT/syslog_log_facility':
  name   => 'DEFAULT/syslog_log_facility',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'LOG_LOCAL2',
}

glance_api_config { 'DEFAULT/use_stderr':
  name   => 'DEFAULT/use_stderr',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'false',
}

glance_api_config { 'DEFAULT/use_syslog':
  name   => 'DEFAULT/use_syslog',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_api_config { 'DEFAULT/use_syslog_rfc_format':
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_api_config { 'DEFAULT/verbose':
  name   => 'DEFAULT/verbose',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_api_config { 'DEFAULT/workers':
  name   => 'DEFAULT/workers',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '4',
}

glance_api_config { 'database/connection':
  name   => 'database/connection',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  secret => 'true',
  value  => 'mysql://glance:385SUUrC@192.168.0.7/glance?read_timeout=60',
}

glance_api_config { 'database/idle_timeout':
  name   => 'database/idle_timeout',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '3600',
}

glance_api_config { 'database/max_overflow':
  name   => 'database/max_overflow',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '20',
}

glance_api_config { 'database/max_pool_size':
  name   => 'database/max_pool_size',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '20',
}

glance_api_config { 'database/max_retries':
  name   => 'database/max_retries',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '-1',
}

glance_api_config { 'glance_store/default_store':
  name   => 'glance_store/default_store',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'rbd',
}

glance_api_config { 'glance_store/os_region_name':
  name   => 'glance_store/os_region_name',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'RegionOne',
}

glance_api_config { 'glance_store/rados_connect_timeout':
  name   => 'glance_store/rados_connect_timeout',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '30',
}

glance_api_config { 'glance_store/rbd_store_ceph_conf':
  name   => 'glance_store/rbd_store_ceph_conf',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '/etc/ceph/ceph.conf',
}

glance_api_config { 'glance_store/rbd_store_chunk_size':
  name   => 'glance_store/rbd_store_chunk_size',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '8',
}

glance_api_config { 'glance_store/rbd_store_pool':
  name   => 'glance_store/rbd_store_pool',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'images',
}

glance_api_config { 'glance_store/rbd_store_user':
  name   => 'glance_store/rbd_store_user',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'images',
}

glance_api_config { 'glance_store/stores':
  name   => 'glance_store/stores',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'glance.store.rbd.Store,glance.store.http.Store',
}

glance_api_config { 'keystone_authtoken/admin_password':
  name   => 'keystone_authtoken/admin_password',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  secret => 'true',
  value  => 'A9KgbnX6',
}

glance_api_config { 'keystone_authtoken/admin_tenant_name':
  name   => 'keystone_authtoken/admin_tenant_name',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'services',
}

glance_api_config { 'keystone_authtoken/admin_user':
  name   => 'keystone_authtoken/admin_user',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'glance',
}

glance_api_config { 'keystone_authtoken/auth_admin_prefix':
  ensure => 'absent',
  name   => 'keystone_authtoken/auth_admin_prefix',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
}

glance_api_config { 'keystone_authtoken/auth_host':
  name   => 'keystone_authtoken/auth_host',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '192.168.0.7',
}

glance_api_config { 'keystone_authtoken/auth_port':
  name   => 'keystone_authtoken/auth_port',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '35357',
}

glance_api_config { 'keystone_authtoken/auth_protocol':
  name   => 'keystone_authtoken/auth_protocol',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'http',
}

glance_api_config { 'keystone_authtoken/auth_uri':
  name   => 'keystone_authtoken/auth_uri',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'http://192.168.0.7:5000/',
}

glance_api_config { 'keystone_authtoken/identity_uri':
  ensure => 'absent',
  name   => 'keystone_authtoken/identity_uri',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
}

glance_api_config { 'keystone_authtoken/signing_dir':
  name   => 'keystone_authtoken/signing_dir',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '/tmp/keystone-signing-glance',
}

glance_api_config { 'keystone_authtoken/token_cache_time':
  name   => 'keystone_authtoken/token_cache_time',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '-1',
}

glance_api_config { 'oslo_messaging_rabbit/heartbeat_rate':
  name   => 'oslo_messaging_rabbit/heartbeat_rate',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '2',
}

glance_api_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold':
  name   => 'oslo_messaging_rabbit/heartbeat_timeout_threshold',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '0',
}

glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_ca_certs',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
}

glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_certfile':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_certfile',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
}

glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_keyfile',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
}

glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_version':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_version',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
}

glance_api_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  name   => 'oslo_messaging_rabbit/rabbit_ha_queues',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_api_config { 'oslo_messaging_rabbit/rabbit_hosts':
  name   => 'oslo_messaging_rabbit/rabbit_hosts',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '192.168.0.3:5673',
}

glance_api_config { 'oslo_messaging_rabbit/rabbit_notification_exchange':
  name   => 'oslo_messaging_rabbit/rabbit_notification_exchange',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'glance',
}

glance_api_config { 'oslo_messaging_rabbit/rabbit_notification_topic':
  name   => 'oslo_messaging_rabbit/rabbit_notification_topic',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'notifications',
}

glance_api_config { 'oslo_messaging_rabbit/rabbit_password':
  name   => 'oslo_messaging_rabbit/rabbit_password',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  secret => 'true',
  value  => '1GXPbTgb',
}

glance_api_config { 'oslo_messaging_rabbit/rabbit_use_ssl':
  name   => 'oslo_messaging_rabbit/rabbit_use_ssl',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'false',
}

glance_api_config { 'oslo_messaging_rabbit/rabbit_userid':
  name   => 'oslo_messaging_rabbit/rabbit_userid',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'nova',
}

glance_api_config { 'oslo_messaging_rabbit/rabbit_virtual_host':
  name   => 'oslo_messaging_rabbit/rabbit_virtual_host',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '/',
}

glance_api_config { 'paste_deploy/flavor':
  ensure => 'present',
  name   => 'paste_deploy/flavor',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'keystone',
}

glance_cache_config { 'DEFAULT/admin_password':
  name   => 'DEFAULT/admin_password',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  secret => 'true',
  value  => 'A9KgbnX6',
}

glance_cache_config { 'DEFAULT/admin_tenant_name':
  name   => 'DEFAULT/admin_tenant_name',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'services',
}

glance_cache_config { 'DEFAULT/admin_user':
  name   => 'DEFAULT/admin_user',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'glance',
}

glance_cache_config { 'DEFAULT/auth_url':
  name   => 'DEFAULT/auth_url',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'http://192.168.0.7:5000/',
}

glance_cache_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'false',
}

glance_cache_config { 'DEFAULT/image_cache_dir':
  name   => 'DEFAULT/image_cache_dir',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '/var/lib/glance/image-cache/',
}

glance_cache_config { 'DEFAULT/image_cache_max_size':
  name   => 'DEFAULT/image_cache_max_size',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '0',
}

glance_cache_config { 'DEFAULT/image_cache_stall_time':
  name   => 'DEFAULT/image_cache_stall_time',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '86400',
}

glance_cache_config { 'DEFAULT/log_file':
  name   => 'DEFAULT/log_file',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '/var/log/glance/image-cache.log',
}

glance_cache_config { 'DEFAULT/os_region_name':
  name   => 'DEFAULT/os_region_name',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'RegionOne',
}

glance_cache_config { 'DEFAULT/registry_host':
  name   => 'DEFAULT/registry_host',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '192.168.0.7',
}

glance_cache_config { 'DEFAULT/registry_port':
  name   => 'DEFAULT/registry_port',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => '9191',
}

glance_cache_config { 'DEFAULT/use_syslog':
  name   => 'DEFAULT/use_syslog',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_cache_config { 'DEFAULT/use_syslog_rfc_format':
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_cache_config { 'DEFAULT/verbose':
  name   => 'DEFAULT/verbose',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_cache_config { 'glance_store/os_region_name':
  name   => 'glance_store/os_region_name',
  notify => ['Service[glance-api]', 'Exec[glance-manage db_sync]'],
  value  => 'RegionOne',
}

glance_registry_config { 'DEFAULT/bind_host':
  name   => 'DEFAULT/bind_host',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '192.168.0.3',
}

glance_registry_config { 'DEFAULT/bind_port':
  name   => 'DEFAULT/bind_port',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '9191',
}

glance_registry_config { 'DEFAULT/ca_file':
  ensure => 'absent',
  name   => 'DEFAULT/ca_file',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
}

glance_registry_config { 'DEFAULT/cert_file':
  ensure => 'absent',
  name   => 'DEFAULT/cert_file',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
}

glance_registry_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'false',
}

glance_registry_config { 'DEFAULT/key_file':
  ensure => 'absent',
  name   => 'DEFAULT/key_file',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
}

glance_registry_config { 'DEFAULT/log_dir':
  name   => 'DEFAULT/log_dir',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '/var/log/glance',
}

glance_registry_config { 'DEFAULT/log_file':
  name   => 'DEFAULT/log_file',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '/var/log/glance/registry.log',
}

glance_registry_config { 'DEFAULT/syslog_log_facility':
  name   => 'DEFAULT/syslog_log_facility',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'LOG_LOCAL2',
}

glance_registry_config { 'DEFAULT/use_stderr':
  name   => 'DEFAULT/use_stderr',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'false',
}

glance_registry_config { 'DEFAULT/use_syslog':
  name   => 'DEFAULT/use_syslog',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_registry_config { 'DEFAULT/use_syslog_rfc_format':
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_registry_config { 'DEFAULT/verbose':
  name   => 'DEFAULT/verbose',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'true',
}

glance_registry_config { 'DEFAULT/workers':
  name   => 'DEFAULT/workers',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '4',
}

glance_registry_config { 'database/connection':
  name   => 'database/connection',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  secret => 'true',
  value  => 'mysql://glance:385SUUrC@192.168.0.7/glance?read_timeout=60',
}

glance_registry_config { 'database/idle_timeout':
  name   => 'database/idle_timeout',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '3600',
}

glance_registry_config { 'database/max_overflow':
  name   => 'database/max_overflow',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '20',
}

glance_registry_config { 'database/max_pool_size':
  name   => 'database/max_pool_size',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '20',
}

glance_registry_config { 'database/max_retries':
  name   => 'database/max_retries',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '-1',
}

glance_registry_config { 'glance_store/os_region_name':
  name   => 'glance_store/os_region_name',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'RegionOne',
}

glance_registry_config { 'keystone_authtoken/admin_password':
  name   => 'keystone_authtoken/admin_password',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  secret => 'true',
  value  => 'A9KgbnX6',
}

glance_registry_config { 'keystone_authtoken/admin_tenant_name':
  name   => 'keystone_authtoken/admin_tenant_name',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'services',
}

glance_registry_config { 'keystone_authtoken/admin_user':
  name   => 'keystone_authtoken/admin_user',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'glance',
}

glance_registry_config { 'keystone_authtoken/auth_admin_prefix':
  ensure => 'absent',
  name   => 'keystone_authtoken/auth_admin_prefix',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
}

glance_registry_config { 'keystone_authtoken/auth_host':
  name   => 'keystone_authtoken/auth_host',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '192.168.0.7',
}

glance_registry_config { 'keystone_authtoken/auth_port':
  name   => 'keystone_authtoken/auth_port',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '35357',
}

glance_registry_config { 'keystone_authtoken/auth_protocol':
  name   => 'keystone_authtoken/auth_protocol',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'http',
}

glance_registry_config { 'keystone_authtoken/auth_uri':
  name   => 'keystone_authtoken/auth_uri',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'http://192.168.0.7:5000/',
}

glance_registry_config { 'keystone_authtoken/identity_uri':
  ensure => 'absent',
  name   => 'keystone_authtoken/identity_uri',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
}

glance_registry_config { 'keystone_authtoken/signing_dir':
  name   => 'keystone_authtoken/signing_dir',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => '/tmp/keystone-signing-glance',
}

glance_registry_config { 'paste_deploy/flavor':
  ensure => 'present',
  name   => 'paste_deploy/flavor',
  notify => ['Service[glance-registry]', 'Exec[glance-manage db_sync]'],
  value  => 'keystone',
}

package { 'glance-api':
  ensure => 'present',
  before => ['File[/etc/glance/]', 'Class[Glance::Policy]', 'Exec[remove_glance-api_override]'],
  name   => 'glance-api',
  notify => 'Exec[glance-manage db_sync]',
  tag    => ['openstack', 'glance-package'],
}

package { 'glance-registry':
  ensure => 'present',
  before => ['File[/etc/glance/]', 'Exec[remove_glance-registry_override]'],
  name   => 'glance-registry',
  notify => 'Exec[glance-manage db_sync]',
  tag    => ['openstack', 'glance-package'],
}

package { 'python-ceph':
  ensure => 'present',
  name   => 'python-ceph',
}

package { 'python-keystone':
  ensure => 'present',
  name   => 'python-keystone',
}

package { 'python-mysqldb':
  ensure => 'present',
  name   => 'python-mysqldb',
}

package { 'python-openstackclient':
  ensure => 'present',
  name   => 'python-openstackclient',
  tag    => 'openstack',
}

resources { 'glance_api_config':
  name  => 'glance_api_config',
  purge => 'false',
}

resources { 'glance_registry_config':
  name  => 'glance_registry_config',
  purge => 'false',
}

service { 'glance-api':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'glance-api',
  tag        => 'glance-service',
}

service { 'glance-registry':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'glance-registry',
  require    => 'Class[Glance]',
  subscribe  => 'File[/etc/glance/glance-registry.conf]',
  tag        => 'glance-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'glance-api':
  name         => 'glance-api',
  package_name => 'glance-api',
  service_name => 'glance-api',
}

tweaks::ubuntu_service_override { 'glance-registry':
  name         => 'glance-registry',
  package_name => 'glance-registry',
  service_name => 'glance-registry',
}

