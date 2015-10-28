anchor { 'nova-start':
  name => 'nova-start',
}

cinder_config { 'DEFAULT/scheduler_default_filters':
  name  => 'DEFAULT/scheduler_default_filters',
  value => 'InstanceLocalityFilter,AvailabilityZoneFilter,CapacityFilter,CapabilitiesFilter',
}

class { 'Cinder::Client':
  name           => 'Cinder::Client',
  package_ensure => 'present',
}

class { 'Cinder::Params':
  name => 'Cinder::Params',
}

class { 'Cinder::Scheduler::Filter':
  name                      => 'Cinder::Scheduler::Filter',
  scheduler_default_filters => ['InstanceLocalityFilter', 'AvailabilityZoneFilter', 'CapacityFilter', 'CapabilitiesFilter'],
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

class { 'Nova::Api':
  admin_password        => 'M9mWs2C0',
  admin_tenant_name     => 'services',
  admin_user            => 'nova',
  api_bind_address      => '10.108.2.4',
  auth_admin_prefix     => 'false',
  auth_host             => '10.108.2.2',
  auth_port             => '35357',
  auth_protocol         => 'http',
  auth_uri              => 'false',
  auth_version          => 'false',
  before                => 'Haproxy_backend_status[nova-api]',
  ec2_workers           => '4',
  enabled               => 'true',
  enabled_apis          => 'ec2,osapi_compute',
  ensure_package        => 'installed',
  identity_uri          => 'false',
  keystone_ec2_url      => 'http://10.108.2.2:5000/v2.0/ec2tokens',
  manage_service        => 'true',
  metadata_listen       => '0.0.0.0',
  metadata_workers      => '4',
  name                  => 'Nova::Api',
  osapi_compute_workers => '4',
  osapi_v3              => 'false',
  ratelimits            => '(POST, *, .*,  100000 , MINUTE);(POST, %(*/servers), ^/servers,  100000 , DAY);(PUT, %(*) , .*,  1000 , MINUTE);(GET, %(*changes-since*), .*changes-since.*, 100000, MINUTE);(DELETE, %(*), .*, 100000 , MINUTE)',
  ratelimits_factory    => 'nova.api.openstack.compute.limits:RateLimitingMiddleware.factory',
  require               => ['Package[nova-common]', 'Class[Keystone::Python]'],
  sync_db               => 'true',
  use_forwarded_for     => 'false',
  validate              => 'false',
  validation_options    => {},
  volume_api_class      => 'nova.volume.cinder.API',
}

class { 'Nova::Cert':
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'Nova::Cert',
}

class { 'Nova::Conductor':
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'Nova::Conductor',
  workers        => '4',
}

class { 'Nova::Config':
  name               => 'Nova::Config',
  nova_config        => {'DEFAULT/force_raw_images' => {'value' => 'undef'}, 'conductor/use_local' => {'value' => 'undef'}},
  nova_paste_api_ini => {},
}

class { 'Nova::Consoleauth':
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'Nova::Consoleauth',
}

class { 'Nova::Db::Sync':
  name => 'Nova::Db::Sync',
}

class { 'Nova::Db':
  name    => 'Nova::Db',
  require => ['Class[Mysql::Bindings]', 'Class[Mysql::Bindings::Python]'],
}

class { 'Nova::Objectstore':
  bind_address   => '0.0.0.0',
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'Nova::Objectstore',
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

class { 'Nova::Quota':
  max_age                               => '0',
  name                                  => 'Nova::Quota',
  quota_cores                           => '100',
  quota_driver                          => 'nova.quota.NoopQuotaDriver',
  quota_fixed_ips                       => '-1',
  quota_floating_ips                    => '100',
  quota_gigabytes                       => '1000',
  quota_injected_file_content_bytes     => '10240',
  quota_injected_file_path_length       => '4096',
  quota_injected_files                  => '5',
  quota_instances                       => '100',
  quota_key_pairs                       => '10',
  quota_max_injected_file_content_bytes => '102400',
  quota_max_injected_files              => '50',
  quota_metadata_items                  => '1024',
  quota_ram                             => '51200',
  quota_security_group_rules            => '20',
  quota_security_groups                 => '10',
  quota_volumes                         => '100',
  reservation_expire                    => '86400',
  until_refresh                         => '0',
}

class { 'Nova::Scheduler::Filter':
  cpu_allocation_ratio            => '8.0',
  disk_allocation_ratio           => '1.0',
  isolated_hosts                  => 'false',
  isolated_images                 => 'false',
  max_instances_per_host          => '50',
  max_io_ops_per_host             => '8',
  name                            => 'Nova::Scheduler::Filter',
  ram_allocation_ratio            => '1.0',
  scheduler_available_filters     => 'nova.scheduler.filters.all_filters',
  scheduler_default_filters       => ['DifferentHostFilter', 'RetryFilter', 'AvailabilityZoneFilter', 'RamFilter', 'CoreFilter', 'DiskFilter', 'ComputeFilter', 'ComputeCapabilitiesFilter', 'ImagePropertiesFilter', 'ServerGroupAntiAffinityFilter', 'ServerGroupAffinityFilter'],
  scheduler_host_manager          => 'nova.scheduler.host_manager.HostManager',
  scheduler_host_subset_size      => '30',
  scheduler_max_attempts          => '3',
  scheduler_use_baremetal_filters => 'false',
  scheduler_weight_classes        => 'nova.scheduler.weights.all_weighers',
}

class { 'Nova::Scheduler':
  enabled          => 'true',
  ensure_package   => 'installed',
  manage_service   => 'true',
  name             => 'Nova::Scheduler',
  scheduler_driver => 'nova.scheduler.filter_scheduler.FilterScheduler',
}

class { 'Nova::Vncproxy::Common':
  name => 'Nova::Vncproxy::Common',
}

class { 'Nova::Vncproxy':
  enabled           => 'true',
  ensure_package    => 'installed',
  host              => '10.108.2.4',
  manage_service    => 'true',
  name              => 'Nova::Vncproxy',
  port              => '6080',
  vncproxy_path     => '/vnc_auto.html',
  vncproxy_protocol => 'http',
}

class { 'Nova':
  amqp_durable_queues                => 'false',
  auth_strategy                      => 'keystone',
  ca_file                            => 'false',
  cert_file                          => 'false',
  database_connection                => 'mysql://nova:2upYv98H@10.108.2.2/nova?read_timeout=60',
  database_idle_timeout              => '3600',
  debug                              => 'true',
  enabled_ssl_apis                   => ['ec2', 'metadata', 'osapi_compute'],
  ensure_package                     => 'installed',
  glance_api_servers                 => '10.108.2.2:9292',
  image_service                      => 'nova.image.glance.GlanceImageService',
  install_utilities                  => 'false',
  key_file                           => 'false',
  kombu_reconnect_delay              => '5.0',
  kombu_ssl_version                  => 'TLSv1',
  lock_path                          => '/var/lock/nova',
  log_dir                            => '/var/log/nova',
  log_facility                       => 'LOG_LOCAL6',
  memcached_servers                  => ['10.108.2.4:11211', '10.108.2.5:11211', '10.108.2.6:11211'],
  name                               => 'Nova',
  notification_driver                => 'messaging',
  notification_topics                => 'notifications',
  notify_api_faults                  => 'false',
  notify_on_state_change             => 'vm_and_task_state',
  periodic_interval                  => '60',
  qpid_heartbeat                     => '60',
  qpid_hostname                      => 'localhost',
  qpid_password                      => 'guest',
  qpid_port                          => '5672',
  qpid_protocol                      => 'tcp',
  qpid_sasl_mechanisms               => 'false',
  qpid_tcp_nodelay                   => 'true',
  qpid_username                      => 'guest',
  rabbit_heartbeat_rate              => '2',
  rabbit_heartbeat_timeout_threshold => '0',
  rabbit_host                        => 'localhost',
  rabbit_hosts                       => ['10.108.2.4:5673', ' 10.108.2.6:5673', ' 10.108.2.5:5673'],
  rabbit_password                    => 'U7sRLche',
  rabbit_port                        => '5672',
  rabbit_use_ssl                     => 'false',
  rabbit_userid                      => 'nova',
  rabbit_virtual_host                => '/',
  report_interval                    => '60',
  rootwrap_config                    => '/etc/nova/rootwrap.conf',
  rpc_backend                        => 'nova.openstack.common.rpc.impl_kombu',
  service_down_time                  => '180',
  slave_connection                   => 'false',
  state_path                         => '/var/lib/nova',
  use_ssl                            => 'false',
  use_stderr                         => 'false',
  use_syslog                         => 'true',
  verbose                            => 'true',
}

class { 'Openstack::Controller':
  admin_address                  => '10.108.2.2',
  allowed_hosts                  => ['%', 'node-1'],
  amqp_hosts                     => '10.108.2.4:5673, 10.108.2.6:5673, 10.108.2.5:5673',
  amqp_password                  => 'U7sRLche',
  amqp_user                      => 'nova',
  api_bind_address               => '10.108.2.4',
  auto_assign_floating_ip        => 'false',
  backend_port                   => 'false',
  backend_timeout                => 'false',
  base_mac                       => 'fa:16:3e:00:00:00',
  cache_server_ip                => ['10.108.2.4', '10.108.2.5', '10.108.2.6'],
  cache_server_port              => '11211',
  ceilometer                     => 'true',
  ceilometer_db_dbname           => 'ceilometer',
  ceilometer_db_host             => '127.0.0.1',
  ceilometer_db_password         => 'ceilometer_pass',
  ceilometer_db_type             => 'mongodb',
  ceilometer_db_user             => 'ceilometer',
  ceilometer_ext_mongo           => 'false',
  ceilometer_metering_secret     => 'ceilometer',
  ceilometer_user_password       => 'ceilometer_pass',
  cinder                         => 'true',
  cinder_db_dbname               => 'cinder',
  cinder_db_password             => 'cinder_db_pass',
  cinder_db_user                 => 'cinder',
  cinder_iscsi_bind_addr         => 'false',
  cinder_user_password           => 'cinder_user_pass',
  cinder_volume_group            => 'cinder-volumes',
  create_networks                => 'true',
  db_host                        => '10.108.2.2',
  db_type                        => 'mysql',
  debug                          => 'true',
  enabled                        => 'true',
  export_resources               => 'true',
  fixed_range                    => '10.0.0.0/16',
  floating_range                 => 'false',
  galera_cluster_name            => 'openstack',
  galera_node_address            => '127.0.0.1',
  galera_nodes                   => '127.0.0.1',
  glance_api_servers             => '10.108.2.2:9292',
  glance_backend                 => 'file',
  glance_db_dbname               => 'glance',
  glance_db_password             => 'glance_pass',
  glance_db_user                 => 'glance',
  glance_image_cache_max_size    => '10737418240',
  glance_user_password           => 'glance_pass',
  ha_mode                        => 'true',
  horizon_use_ssl                => 'false',
  idle_timeout                   => '3600',
  internal_address               => '10.108.2.2',
  keystone_admin_tenant          => 'admin',
  keystone_admin_token           => 'keystone_admin_token',
  keystone_db_dbname             => 'keystone',
  keystone_db_password           => 'keystone_pass',
  keystone_db_user               => 'keystone',
  known_stores                   => 'false',
  manage_volumes                 => 'false',
  max_overflow                   => '20',
  max_pool_size                  => '20',
  max_retries                    => '-1',
  multi_host                     => 'true',
  mysql_account_security         => 'true',
  mysql_bind_address             => '0.0.0.0',
  mysql_root_password            => 'sql_pass',
  mysql_skip_name_resolve        => 'false',
  name                           => 'Openstack::Controller',
  network_config                 => {},
  network_manager                => 'nova.network.manager.FlatDHCPManager',
  network_provider               => 'nova',
  network_size                   => '65536',
  neutron_db_dbname              => 'neutron',
  neutron_db_password            => 'neutron_db_pass',
  neutron_db_user                => 'neutron',
  neutron_ha_agents              => 'false',
  neutron_metadata_proxy_secret  => '12345',
  neutron_user_password          => 'asdf123',
  nova_db_dbname                 => 'nova',
  nova_db_password               => '2upYv98H',
  nova_db_user                   => 'nova',
  nova_hash                      => {'db_password' => '2upYv98H', 'state_path' => '/var/lib/nova', 'user_password' => 'M9mWs2C0'},
  nova_rate_limits               => {'DELETE' => '100000', 'GET' => '100000', 'POST' => '100000', 'POST_SERVERS' => '100000', 'PUT' => '1000'},
  nova_report_interval           => '60',
  nova_service_down_time         => '180',
  nova_user                      => 'nova',
  nova_user_password             => 'M9mWs2C0',
  nova_user_tenant               => 'services',
  novnc_address                  => '10.108.2.4',
  num_networks                   => '1',
  primary_controller             => 'true',
  private_interface              => 'eth3.103',
  public_address                 => '10.108.1.2',
  public_interface               => '',
  purge_nova_config              => 'false',
  queue_provider                 => 'rabbitmq',
  rabbit_ha_queues               => 'true',
  rabbitmq_bind_ip_address       => 'UNSET',
  rabbitmq_bind_port             => '5672',
  rabbitmq_cluster_nodes         => [],
  secret_key                     => 'dummy_secret_key',
  segment_range                  => '1:4094',
  service_endpoint               => '10.108.2.2',
  service_workers                => '4',
  status_check                   => 'false',
  status_password                => 'false',
  status_user                    => 'false',
  swift                          => 'false',
  swift_rados_backend            => 'false',
  syslog_log_facility_ceilometer => 'LOG_LOCAL0',
  syslog_log_facility_cinder     => 'LOG_LOCAL3',
  syslog_log_facility_glance     => 'LOG_LOCAL2',
  syslog_log_facility_keystone   => 'LOG_LOCAL7',
  syslog_log_facility_neutron    => 'LOG_LOCAL4',
  syslog_log_facility_nova       => 'LOG_LOCAL6',
  tenant_network_type            => 'gre',
  use_stderr                     => 'false',
  use_syslog                     => 'true',
  verbose                        => 'true',
}

class { 'Openstack::Nova::Controller':
  admin_address               => '10.108.2.2',
  amqp_hosts                  => '10.108.2.4:5673, 10.108.2.6:5673, 10.108.2.5:5673',
  amqp_password               => 'U7sRLche',
  amqp_user                   => 'nova',
  api_bind_address            => '10.108.2.4',
  auto_assign_floating_ip     => 'false',
  cache_server_ip             => ['10.108.2.4', '10.108.2.5', '10.108.2.6'],
  cache_server_port           => '11211',
  ceilometer                  => 'true',
  cinder                      => 'true',
  cluster_partition_handling  => 'autoheal',
  create_networks             => 'true',
  db_host                     => '10.108.2.2',
  db_type                     => 'mysql',
  debug                       => 'true',
  enabled                     => 'true',
  enabled_apis                => 'ec2,osapi_compute',
  ensure_package              => 'installed',
  exported_resources          => 'true',
  fixed_range                 => '10.0.0.0/16',
  floating_range              => 'false',
  glance_api_servers          => '10.108.2.2:9292',
  ha_mode                     => 'true',
  idle_timeout                => '3600',
  internal_address            => '10.108.2.2',
  keystone_host               => '10.108.2.2',
  max_overflow                => '20',
  max_pool_size               => '20',
  max_retries                 => '-1',
  multi_host                  => 'true',
  name                        => 'Openstack::Nova::Controller',
  network_config              => {},
  network_manager             => 'nova.network.manager.FlatDHCPManager',
  network_size                => '65536',
  neutron                     => 'false',
  nova_db_dbname              => 'nova',
  nova_db_password            => '2upYv98H',
  nova_db_user                => 'nova',
  nova_hash                   => {'db_password' => '2upYv98H', 'state_path' => '/var/lib/nova', 'user_password' => 'M9mWs2C0'},
  nova_quota_driver           => 'nova.quota.NoopQuotaDriver',
  nova_rate_limits            => {'DELETE' => '100000', 'GET' => '100000', 'POST' => '100000', 'POST_SERVERS' => '100000', 'PUT' => '1000'},
  nova_report_interval        => '60',
  nova_service_down_time      => '180',
  nova_user                   => 'nova',
  nova_user_password          => 'M9mWs2C0',
  nova_user_tenant            => 'services',
  novnc_address               => '10.108.2.4',
  num_networks                => '1',
  primary_controller          => 'true',
  private_interface           => 'eth3.103',
  public_address              => '10.108.1.2',
  public_interface            => '',
  queue_provider              => 'rabbitmq',
  rabbit_ha_queues            => 'true',
  rabbitmq_bind_ip_address    => 'UNSET',
  rabbitmq_bind_port          => '5672',
  rabbitmq_cluster_nodes      => [],
  rpc_backend                 => 'nova.openstack.common.rpc.impl_kombu',
  segment_range               => '1:4094',
  service_endpoint            => '10.108.2.2',
  service_workers             => '4',
  syslog_log_facility         => 'LOG_LOCAL6',
  syslog_log_facility_neutron => 'LOG_LOCAL4',
  tenant_network_type         => 'gre',
  use_stderr                  => 'false',
  use_syslog                  => 'true',
  verbose                     => 'true',
  vnc_enabled                 => 'true',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'create-m1.micro-flavor':
  command     => 'bash -c "nova flavor-create --is-public true m1.micro auto 64 0 1"',
  environment => ['OS_TENANT_NAME=services', 'OS_USERNAME=nova', 'OS_PASSWORD=M9mWs2C0', 'OS_AUTH_URL=http://10.108.2.2:5000/v2.0/', 'OS_ENDPOINT_TYPE=internalURL', 'OS_REGION_NAME=RegionOne', 'NOVA_ENDPOINT_TYPE=internalURL'],
  path        => '/sbin:/usr/sbin:/bin:/usr/bin',
  require     => 'Class[Nova]',
  tries       => '10',
  try_sleep   => '2',
  unless      => 'bash -c "nova flavor-list | grep -q m1.micro"',
}

exec { 'networking-refresh':
  command     => '/sbin/ifdown -a ; /sbin/ifup -a',
  refreshonly => 'true',
}

exec { 'nova-db-sync':
  command     => '/usr/bin/nova-manage db sync',
  logoutput   => 'on_failure',
  notify      => ['Service[nova-api]', 'Service[nova-conductor]', 'Service[nova-scheduler]', 'Service[nova-objectstore]', 'Service[nova-cert]', 'Service[nova-consoleauth]', 'Service[nova-vncproxy]', 'Service[nova-api]', 'Service[nova-conductor]', 'Service[nova-scheduler]', 'Service[nova-objectstore]', 'Service[nova-cert]', 'Service[nova-consoleauth]', 'Service[nova-vncproxy]'],
  refreshonly => 'true',
}

exec { 'post-nova_config':
  command     => '/bin/echo "Nova config has changed"',
  notify      => ['Exec[nova-db-sync]', 'Service[nova-api]', 'Service[nova-conductor]', 'Service[nova-scheduler]', 'Service[nova-objectstore]', 'Service[nova-cert]', 'Service[nova-consoleauth]', 'Service[nova-vncproxy]'],
  refreshonly => 'true',
}

exec { 'remove_nova-api_override':
  before  => ['Service[nova-api]', 'Service[nova-api]'],
  command => 'rm -f /etc/init/nova-api.override',
  onlyif  => 'test -f /etc/init/nova-api.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-cells_override':
  command => 'rm -f /etc/init/nova-cells.override',
  onlyif  => 'test -f /etc/init/nova-cells.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-cert_override':
  before  => ['Service[nova-cert]', 'Service[nova-cert]'],
  command => 'rm -f /etc/init/nova-cert.override',
  onlyif  => 'test -f /etc/init/nova-cert.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-conductor_override':
  before  => ['Service[nova-conductor]', 'Service[nova-conductor]'],
  command => 'rm -f /etc/init/nova-conductor.override',
  onlyif  => 'test -f /etc/init/nova-conductor.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-consoleauth_override':
  before  => ['Service[nova-consoleauth]', 'Service[nova-consoleauth]'],
  command => 'rm -f /etc/init/nova-consoleauth.override',
  onlyif  => 'test -f /etc/init/nova-consoleauth.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-consoleproxy_override':
  command => 'rm -f /etc/init/nova-consoleproxy.override',
  onlyif  => 'test -f /etc/init/nova-consoleproxy.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-objectstore_override':
  before  => ['Service[nova-objectstore]', 'Service[nova-objectstore]'],
  command => 'rm -f /etc/init/nova-objectstore.override',
  onlyif  => 'test -f /etc/init/nova-objectstore.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-scheduler_override':
  before  => ['Service[nova-scheduler]', 'Service[nova-scheduler]'],
  command => 'rm -f /etc/init/nova-scheduler.override',
  onlyif  => 'test -f /etc/init/nova-scheduler.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-spicehtml5proxy_override':
  command => 'rm -f /etc/init/nova-spicehtml5proxy.override',
  onlyif  => 'test -f /etc/init/nova-spicehtml5proxy.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-spiceproxy_override':
  command => 'rm -f /etc/init/nova-spiceproxy.override',
  onlyif  => 'test -f /etc/init/nova-spiceproxy.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_nova-vncproxy_override':
  before  => 'Service[nova-vncproxy]',
  command => 'rm -f /etc/init/nova-vncproxy.override',
  onlyif  => 'test -f /etc/init/nova-vncproxy.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/etc/nova/nova.conf':
  group   => 'nova',
  mode    => '0640',
  owner   => 'nova',
  path    => '/etc/nova/nova.conf',
  require => 'Package[nova-common]',
}

file { '/var/log/nova':
  ensure  => 'directory',
  group   => 'adm',
  mode    => '0750',
  owner   => 'nova',
  path    => '/var/log/nova',
  require => 'Package[nova-common]',
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

file { 'create_nova-cells_override':
  ensure  => 'present',
  before  => 'Exec[remove_nova-cells_override]',
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-cells.override',
}

file { 'create_nova-cert_override':
  ensure  => 'present',
  before  => ['Package[nova-cert]', 'Package[nova-cert]', 'Exec[remove_nova-cert_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-cert.override',
}

file { 'create_nova-conductor_override':
  ensure  => 'present',
  before  => ['Package[nova-conductor]', 'Package[nova-conductor]', 'Exec[remove_nova-conductor_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-conductor.override',
}

file { 'create_nova-consoleauth_override':
  ensure  => 'present',
  before  => ['Package[nova-consoleauth]', 'Package[nova-consoleauth]', 'Exec[remove_nova-consoleauth_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-consoleauth.override',
}

file { 'create_nova-consoleproxy_override':
  ensure  => 'present',
  before  => ['Package[nova-vncproxy]', 'Exec[remove_nova-consoleproxy_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-consoleproxy.override',
}

file { 'create_nova-objectstore_override':
  ensure  => 'present',
  before  => ['Package[nova-objectstore]', 'Package[nova-objectstore]', 'Exec[remove_nova-objectstore_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-objectstore.override',
}

file { 'create_nova-scheduler_override':
  ensure  => 'present',
  before  => ['Package[nova-scheduler]', 'Package[nova-scheduler]', 'Exec[remove_nova-scheduler_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-scheduler.override',
}

file { 'create_nova-spicehtml5proxy_override':
  ensure  => 'present',
  before  => 'Exec[remove_nova-spicehtml5proxy_override]',
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-spicehtml5proxy.override',
}

file { 'create_nova-spiceproxy_override':
  ensure  => 'present',
  before  => 'Exec[remove_nova-spiceproxy_override]',
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-spiceproxy.override',
}

file { 'create_nova-vncproxy_override':
  ensure  => 'present',
  before  => ['Package[nova-vncproxy]', 'Exec[remove_nova-vncproxy_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-vncproxy.override',
}

haproxy_backend_status { 'nova-api':
  before => ['Exec[create-m1.micro-flavor]', 'Nova_floating_range[10.108.1.128-10.108.1.254]'],
  name   => 'nova-api-2',
  url    => 'http://10.108.2.2:10000/;csv',
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

nova::generic_service { 'cert':
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'cert',
  package_name   => 'nova-cert',
  service_name   => 'nova-cert',
}

nova::generic_service { 'conductor':
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'conductor',
  package_name   => 'nova-conductor',
  service_name   => 'nova-conductor',
}

nova::generic_service { 'consoleauth':
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'consoleauth',
  package_name   => 'nova-consoleauth',
  require        => 'Package[nova-common]',
  service_name   => 'nova-consoleauth',
}

nova::generic_service { 'objectstore':
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'objectstore',
  package_name   => 'nova-objectstore',
  require        => 'Package[nova-common]',
  service_name   => 'nova-objectstore',
}

nova::generic_service { 'scheduler':
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'scheduler',
  package_name   => 'nova-scheduler',
  service_name   => 'nova-scheduler',
}

nova::generic_service { 'vncproxy':
  enabled        => 'true',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'vncproxy',
  package_name   => 'nova-novncproxy',
  require        => 'Package[python-numpy]',
  service_name   => 'nova-novncproxy',
}

nova_config { 'DATABASE/max_overflow':
  before => 'Exec[nova-db-sync]',
  name   => 'DATABASE/max_overflow',
  notify => 'Exec[post-nova_config]',
  value  => '20',
}

nova_config { 'DATABASE/max_pool_size':
  before => 'Exec[nova-db-sync]',
  name   => 'DATABASE/max_pool_size',
  notify => 'Exec[post-nova_config]',
  value  => '20',
}

nova_config { 'DATABASE/max_retries':
  before => 'Exec[nova-db-sync]',
  name   => 'DATABASE/max_retries',
  notify => 'Exec[post-nova_config]',
  value  => '-1',
}

nova_config { 'DEFAULT/allow_resize_to_same_host':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/allow_resize_to_same_host',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/amqp_durable_queues':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/amqp_durable_queues',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'DEFAULT/api_paste_config':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/api_paste_config',
  notify => 'Exec[post-nova_config]',
  value  => '/etc/nova/api-paste.ini',
}

nova_config { 'DEFAULT/auth_strategy':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/auth_strategy',
  notify => 'Exec[post-nova_config]',
  value  => 'keystone',
}

nova_config { 'DEFAULT/baremetal_scheduler_default_filters':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/baremetal_scheduler_default_filters',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/cpu_allocation_ratio':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/cpu_allocation_ratio',
  notify => 'Exec[post-nova_config]',
  value  => '8.0',
}

nova_config { 'DEFAULT/debug':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/debug',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/disk_allocation_ratio':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/disk_allocation_ratio',
  notify => 'Exec[post-nova_config]',
  value  => '1.0',
}

nova_config { 'DEFAULT/ec2_listen':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/ec2_listen',
  notify => 'Exec[post-nova_config]',
  value  => '10.108.2.4',
}

nova_config { 'DEFAULT/ec2_workers':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/ec2_workers',
  notify => 'Exec[post-nova_config]',
  value  => '4',
}

nova_config { 'DEFAULT/enabled_apis':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/enabled_apis',
  notify => 'Exec[post-nova_config]',
  value  => 'ec2,osapi_compute',
}

nova_config { 'DEFAULT/enabled_ssl_apis':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/enabled_ssl_apis',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/force_raw_images':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/force_raw_images',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/fping_path':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/fping_path',
  notify => 'Exec[post-nova_config]',
  value  => '/usr/bin/fping',
}

nova_config { 'DEFAULT/image_service':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/image_service',
  notify => 'Exec[post-nova_config]',
  value  => 'nova.image.glance.GlanceImageService',
}

nova_config { 'DEFAULT/isolated_hosts':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/isolated_hosts',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/isolated_images':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/isolated_images',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/keystone_ec2_url':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/keystone_ec2_url',
  notify => 'Exec[post-nova_config]',
  value  => 'http://10.108.2.2:5000/v2.0/ec2tokens',
}

nova_config { 'DEFAULT/lock_path':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/lock_path',
  notify => 'Exec[post-nova_config]',
  value  => '/var/lock/nova',
}

nova_config { 'DEFAULT/log_dir':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/log_dir',
  notify => 'Exec[post-nova_config]',
  value  => '/var/log/nova',
}

nova_config { 'DEFAULT/max_age':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/max_age',
  notify => 'Exec[post-nova_config]',
  value  => '0',
}

nova_config { 'DEFAULT/max_instances_per_host':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/max_instances_per_host',
  notify => 'Exec[post-nova_config]',
  value  => '50',
}

nova_config { 'DEFAULT/max_io_ops_per_host':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/max_io_ops_per_host',
  notify => 'Exec[post-nova_config]',
  value  => '8',
}

nova_config { 'DEFAULT/memcached_servers':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/memcached_servers',
  notify => 'Exec[post-nova_config]',
  value  => '10.108.2.4:11211,10.108.2.5:11211,10.108.2.6:11211',
}

nova_config { 'DEFAULT/metadata_listen':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/metadata_listen',
  notify => 'Exec[post-nova_config]',
  value  => '0.0.0.0',
}

nova_config { 'DEFAULT/metadata_workers':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/metadata_workers',
  notify => 'Exec[post-nova_config]',
  value  => '4',
}

nova_config { 'DEFAULT/multi_host':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/multi_host',
  notify => 'Exec[post-nova_config]',
  value  => 'True',
}

nova_config { 'DEFAULT/notification_driver':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/notification_driver',
  notify => 'Exec[post-nova_config]',
  value  => 'messaging',
}

nova_config { 'DEFAULT/notification_topics':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/notification_topics',
  notify => 'Exec[post-nova_config]',
  value  => 'notifications',
}

nova_config { 'DEFAULT/notify_api_faults':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/notify_api_faults',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'DEFAULT/notify_on_state_change':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/notify_on_state_change',
  notify => 'Exec[post-nova_config]',
  value  => 'vm_and_task_state',
}

nova_config { 'DEFAULT/novncproxy_base_url':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/novncproxy_base_url',
  notify => 'Exec[post-nova_config]',
  value  => 'http://10.108.2.4:6080/vnc_auto.html',
}

nova_config { 'DEFAULT/novncproxy_host':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/novncproxy_host',
  notify => 'Exec[post-nova_config]',
  value  => '10.108.2.4',
}

nova_config { 'DEFAULT/novncproxy_port':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/novncproxy_port',
  notify => 'Exec[post-nova_config]',
  value  => '6080',
}

nova_config { 'DEFAULT/os_region_name':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/os_region_name',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/osapi_compute_listen':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/osapi_compute_listen',
  notify => 'Exec[post-nova_config]',
  value  => '10.108.2.4',
}

nova_config { 'DEFAULT/osapi_compute_workers':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/osapi_compute_workers',
  notify => 'Exec[post-nova_config]',
  value  => '4',
}

nova_config { 'DEFAULT/osapi_volume_listen':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/osapi_volume_listen',
  notify => 'Exec[post-nova_config]',
  value  => '10.108.2.4',
}

nova_config { 'DEFAULT/quota_cores':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_cores',
  notify => 'Exec[post-nova_config]',
  value  => '100',
}

nova_config { 'DEFAULT/quota_driver':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_driver',
  notify => 'Exec[post-nova_config]',
  value  => 'nova.quota.NoopQuotaDriver',
}

nova_config { 'DEFAULT/quota_fixed_ips':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_fixed_ips',
  notify => 'Exec[post-nova_config]',
  value  => '-1',
}

nova_config { 'DEFAULT/quota_floating_ips':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_floating_ips',
  notify => 'Exec[post-nova_config]',
  value  => '100',
}

nova_config { 'DEFAULT/quota_injected_file_content_bytes':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_injected_file_content_bytes',
  notify => 'Exec[post-nova_config]',
  value  => '102400',
}

nova_config { 'DEFAULT/quota_injected_file_path_length':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_injected_file_path_length',
  notify => 'Exec[post-nova_config]',
  value  => '4096',
}

nova_config { 'DEFAULT/quota_injected_files':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_injected_files',
  notify => 'Exec[post-nova_config]',
  value  => '50',
}

nova_config { 'DEFAULT/quota_instances':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_instances',
  notify => 'Exec[post-nova_config]',
  value  => '100',
}

nova_config { 'DEFAULT/quota_key_pairs':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_key_pairs',
  notify => 'Exec[post-nova_config]',
  value  => '10',
}

nova_config { 'DEFAULT/quota_metadata_items':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_metadata_items',
  notify => 'Exec[post-nova_config]',
  value  => '1024',
}

nova_config { 'DEFAULT/quota_ram':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_ram',
  notify => 'Exec[post-nova_config]',
  value  => '51200',
}

nova_config { 'DEFAULT/quota_security_group_rules':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_security_group_rules',
  notify => 'Exec[post-nova_config]',
  value  => '20',
}

nova_config { 'DEFAULT/quota_security_groups':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/quota_security_groups',
  notify => 'Exec[post-nova_config]',
  value  => '10',
}

nova_config { 'DEFAULT/ram_allocation_ratio':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/ram_allocation_ratio',
  notify => 'Exec[post-nova_config]',
  value  => '1.0',
}

nova_config { 'DEFAULT/ram_weight_multiplier':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/ram_weight_multiplier',
  notify => 'Exec[post-nova_config]',
  value  => '1.0',
}

nova_config { 'DEFAULT/report_interval':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/report_interval',
  notify => 'Exec[post-nova_config]',
  value  => '60',
}

nova_config { 'DEFAULT/reservation_expire':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/reservation_expire',
  notify => 'Exec[post-nova_config]',
  value  => '86400',
}

nova_config { 'DEFAULT/rootwrap_config':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/rootwrap_config',
  notify => 'Exec[post-nova_config]',
  value  => '/etc/nova/rootwrap.conf',
}

nova_config { 'DEFAULT/rpc_backend':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/rpc_backend',
  notify => 'Exec[post-nova_config]',
  value  => 'nova.openstack.common.rpc.impl_kombu',
}

nova_config { 'DEFAULT/s3_listen':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/s3_listen',
  notify => 'Exec[post-nova_config]',
  value  => '0.0.0.0',
}

nova_config { 'DEFAULT/scheduler_available_filters':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/scheduler_available_filters',
  notify => 'Exec[post-nova_config]',
  value  => 'nova.scheduler.filters.all_filters',
}

nova_config { 'DEFAULT/scheduler_default_filters':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/scheduler_default_filters',
  notify => 'Exec[post-nova_config]',
  value  => 'DifferentHostFilter,RetryFilter,AvailabilityZoneFilter,RamFilter,CoreFilter,DiskFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter',
}

nova_config { 'DEFAULT/scheduler_driver':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/scheduler_driver',
  notify => ['Exec[post-nova_config]', 'Service[nova-scheduler]'],
  value  => 'nova.scheduler.filter_scheduler.FilterScheduler',
}

nova_config { 'DEFAULT/scheduler_host_manager':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/scheduler_host_manager',
  notify => 'Exec[post-nova_config]',
  value  => 'nova.scheduler.host_manager.HostManager',
}

nova_config { 'DEFAULT/scheduler_host_subset_size':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/scheduler_host_subset_size',
  notify => 'Exec[post-nova_config]',
  value  => '30',
}

nova_config { 'DEFAULT/scheduler_max_attempts':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/scheduler_max_attempts',
  notify => 'Exec[post-nova_config]',
  value  => '3',
}

nova_config { 'DEFAULT/scheduler_use_baremetal_filters':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/scheduler_use_baremetal_filters',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'DEFAULT/scheduler_weight_classes':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/scheduler_weight_classes',
  notify => 'Exec[post-nova_config]',
  value  => 'nova.scheduler.weights.all_weighers',
}

nova_config { 'DEFAULT/service_down_time':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/service_down_time',
  notify => 'Exec[post-nova_config]',
  value  => '180',
}

nova_config { 'DEFAULT/ssl_ca_file':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/ssl_ca_file',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/ssl_cert_file':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/ssl_cert_file',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/ssl_key_file':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/ssl_key_file',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/state_path':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/state_path',
  notify => 'Exec[post-nova_config]',
  value  => '/var/lib/nova',
}

nova_config { 'DEFAULT/syslog_log_facility':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/syslog_log_facility',
  notify => 'Exec[post-nova_config]',
  value  => 'LOG_LOCAL6',
}

nova_config { 'DEFAULT/teardown_unused_network_gateway':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/teardown_unused_network_gateway',
  notify => 'Exec[post-nova_config]',
  value  => 'True',
}

nova_config { 'DEFAULT/until_refresh':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/until_refresh',
  notify => 'Exec[post-nova_config]',
  value  => '0',
}

nova_config { 'DEFAULT/use_cow_images':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/use_cow_images',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/use_forwarded_for':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/use_forwarded_for',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'DEFAULT/use_stderr':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/use_stderr',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'DEFAULT/use_syslog':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/use_syslog',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/use_syslog_rfc_format':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/verbose':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/verbose',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/volume_api_class':
  before => 'Exec[nova-db-sync]',
  name   => 'DEFAULT/volume_api_class',
  notify => 'Exec[post-nova_config]',
  value  => 'nova.volume.cinder.API',
}

nova_config { 'cinder/catalog_info':
  before => 'Exec[nova-db-sync]',
  name   => 'cinder/catalog_info',
  notify => 'Exec[post-nova_config]',
  value  => 'volume:cinder:internalURL',
}

nova_config { 'cinder/os_region_name':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'cinder/os_region_name',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'conductor/use_local':
  before => 'Exec[nova-db-sync]',
  name   => 'conductor/use_local',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'conductor/workers':
  before => 'Exec[nova-db-sync]',
  name   => 'conductor/workers',
  notify => 'Exec[post-nova_config]',
  value  => '4',
}

nova_config { 'database/connection':
  before => 'Exec[nova-db-sync]',
  name   => 'database/connection',
  notify => ['Exec[post-nova_config]', 'Exec[nova-db-sync]'],
  secret => 'true',
  value  => 'mysql://nova:2upYv98H@10.108.2.2/nova?read_timeout=60',
}

nova_config { 'database/idle_timeout':
  before => 'Exec[nova-db-sync]',
  name   => 'database/idle_timeout',
  notify => 'Exec[post-nova_config]',
  value  => '3600',
}

nova_config { 'database/slave_connection':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'database/slave_connection',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'glance/api_servers':
  before => 'Exec[nova-db-sync]',
  name   => 'glance/api_servers',
  notify => 'Exec[post-nova_config]',
  value  => '10.108.2.2:9292',
}

nova_config { 'keystone_authtoken/admin_password':
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/admin_password',
  notify => 'Exec[post-nova_config]',
  secret => 'true',
  value  => 'M9mWs2C0',
}

nova_config { 'keystone_authtoken/admin_tenant_name':
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/admin_tenant_name',
  notify => 'Exec[post-nova_config]',
  value  => 'services',
}

nova_config { 'keystone_authtoken/admin_user':
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/admin_user',
  notify => 'Exec[post-nova_config]',
  value  => 'nova',
}

nova_config { 'keystone_authtoken/auth_admin_prefix':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/auth_admin_prefix',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'keystone_authtoken/auth_host':
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/auth_host',
  notify => 'Exec[post-nova_config]',
  value  => '10.108.2.2',
}

nova_config { 'keystone_authtoken/auth_port':
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/auth_port',
  notify => 'Exec[post-nova_config]',
  value  => '35357',
}

nova_config { 'keystone_authtoken/auth_protocol':
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/auth_protocol',
  notify => 'Exec[post-nova_config]',
  value  => 'http',
}

nova_config { 'keystone_authtoken/auth_uri':
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/auth_uri',
  notify => 'Exec[post-nova_config]',
  value  => 'http://10.108.2.2:5000/',
}

nova_config { 'keystone_authtoken/auth_version':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/auth_version',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'keystone_authtoken/identity_uri':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/identity_uri',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'keystone_authtoken/signing_dir':
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/signing_dir',
  notify => 'Exec[post-nova_config]',
  value  => '/tmp/keystone-signing-nova',
}

nova_config { 'keystone_authtoken/signing_dirname':
  before => 'Exec[nova-db-sync]',
  name   => 'keystone_authtoken/signing_dirname',
  notify => 'Exec[post-nova_config]',
  value  => '/tmp/keystone-signing-nova',
}

nova_config { 'neutron/metadata_proxy_shared_secret':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'neutron/metadata_proxy_shared_secret',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'neutron/service_metadata_proxy':
  before => 'Exec[nova-db-sync]',
  name   => 'neutron/service_metadata_proxy',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'osapi_v3/enabled':
  before => 'Exec[nova-db-sync]',
  name   => 'osapi_v3/enabled',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'oslo_messaging_rabbit/heartbeat_rate':
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/heartbeat_rate',
  notify => 'Exec[post-nova_config]',
  value  => '2',
}

nova_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold':
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/heartbeat_timeout_threshold',
  notify => 'Exec[post-nova_config]',
  value  => '0',
}

nova_config { 'oslo_messaging_rabbit/kombu_reconnect_delay':
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/kombu_reconnect_delay',
  notify => 'Exec[post-nova_config]',
  value  => '5.0',
}

nova_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/kombu_ssl_ca_certs',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'oslo_messaging_rabbit/kombu_ssl_certfile':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/kombu_ssl_certfile',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/kombu_ssl_keyfile',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'oslo_messaging_rabbit/kombu_ssl_version':
  ensure => 'absent',
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/kombu_ssl_version',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/rabbit_ha_queues',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'oslo_messaging_rabbit/rabbit_hosts':
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/rabbit_hosts',
  notify => 'Exec[post-nova_config]',
  value  => '10.108.2.4:5673, 10.108.2.6:5673, 10.108.2.5:5673',
}

nova_config { 'oslo_messaging_rabbit/rabbit_password':
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/rabbit_password',
  notify => 'Exec[post-nova_config]',
  secret => 'true',
  value  => 'U7sRLche',
}

nova_config { 'oslo_messaging_rabbit/rabbit_use_ssl':
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/rabbit_use_ssl',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'oslo_messaging_rabbit/rabbit_userid':
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/rabbit_userid',
  notify => 'Exec[post-nova_config]',
  value  => 'nova',
}

nova_config { 'oslo_messaging_rabbit/rabbit_virtual_host':
  before => 'Exec[nova-db-sync]',
  name   => 'oslo_messaging_rabbit/rabbit_virtual_host',
  notify => 'Exec[post-nova_config]',
  value  => '/',
}

nova_floating_range { '10.108.1.128-10.108.1.254':
  ensure          => 'present',
  api_key         => 'ceilometerHA',
  api_retries     => '10',
  auth_method     => 'password',
  auth_url        => 'http://10.108.2.2:5000/v2.0/',
  authtenant_name => 'ceilometerHA',
  name            => '10.108.1.128-10.108.1.254',
  pool            => 'nova',
  username        => 'ceilometerHA',
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

nova_paste_api_ini { 'filter:authtoken/signing_dir':
  ensure => 'absent',
  name   => 'filter:authtoken/signing_dir',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
}

nova_paste_api_ini { 'filter:authtoken/signing_dirname':
  ensure => 'absent',
  name   => 'filter:authtoken/signing_dirname',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
}

nova_paste_api_ini { 'filter:ratelimit/limits':
  name   => 'filter:ratelimit/limits',
  notify => ['Exec[post-nova_config]', 'Service[nova-api]'],
  value  => '(POST, *, .*,  100000 , MINUTE);(POST, %(*/servers), ^/servers,  100000 , DAY);(PUT, %(*) , .*,  1000 , MINUTE);(GET, %(*changes-since*), .*changes-since.*, 100000, MINUTE);(DELETE, %(*), .*, 100000 , MINUTE)',
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

package { 'nova-cert':
  ensure => 'installed',
  before => ['Service[nova-cert]', 'Service[nova-cert]', 'Exec[remove_nova-cert_override]', 'Exec[remove_nova-cert_override]'],
  name   => 'nova-cert',
  notify => ['Service[nova-cert]', 'Exec[nova-db-sync]'],
  tag    => ['openstack', 'nova-package'],
}

package { 'nova-common':
  ensure  => 'installed',
  before  => ['Class[Nova::Api]', 'Class[Nova::Policy]'],
  name    => 'nova-common',
  notify  => 'Exec[nova-db-sync]',
  require => ['Package[python-nova]', 'Anchor[nova-start]'],
  tag     => ['openstack', 'nova-package'],
}

package { 'nova-conductor':
  ensure => 'installed',
  before => ['Service[nova-conductor]', 'Service[nova-conductor]', 'Exec[remove_nova-conductor_override]', 'Exec[remove_nova-conductor_override]'],
  name   => 'nova-conductor',
  notify => ['Service[nova-conductor]', 'Exec[nova-db-sync]'],
  tag    => ['openstack', 'nova-package'],
}

package { 'nova-consoleauth':
  ensure => 'installed',
  before => ['Service[nova-consoleauth]', 'Service[nova-consoleauth]', 'Exec[remove_nova-consoleauth_override]', 'Exec[remove_nova-consoleauth_override]'],
  name   => 'nova-consoleauth',
  notify => ['Service[nova-consoleauth]', 'Exec[nova-db-sync]'],
  tag    => ['openstack', 'nova-package'],
}

package { 'nova-objectstore':
  ensure => 'installed',
  before => ['Service[nova-objectstore]', 'Service[nova-objectstore]', 'Exec[remove_nova-objectstore_override]', 'Exec[remove_nova-objectstore_override]'],
  name   => 'nova-objectstore',
  notify => ['Service[nova-objectstore]', 'Exec[nova-db-sync]'],
  tag    => ['openstack', 'nova-package'],
}

package { 'nova-scheduler':
  ensure => 'installed',
  before => ['Service[nova-scheduler]', 'Service[nova-scheduler]', 'Exec[remove_nova-scheduler_override]', 'Exec[remove_nova-scheduler_override]'],
  name   => 'nova-scheduler',
  notify => ['Service[nova-scheduler]', 'Exec[nova-db-sync]'],
  tag    => ['openstack', 'nova-package'],
}

package { 'nova-vncproxy':
  ensure => 'installed',
  before => ['Service[nova-vncproxy]', 'Exec[remove_nova-consoleproxy_override]', 'Exec[remove_nova-vncproxy_override]'],
  name   => 'nova-consoleproxy',
  notify => ['Service[nova-vncproxy]', 'Exec[nova-db-sync]'],
  tag    => ['openstack', 'nova-package'],
}

package { 'python-cinderclient':
  ensure => 'present',
  name   => 'python-cinderclient',
  tag    => 'openstack',
}

package { 'python-greenlet':
  ensure => 'present',
  name   => 'python-greenlet',
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

package { 'python-mysqldb':
  ensure => 'present',
  name   => 'python-mysqldb',
}

package { 'python-nova':
  ensure  => 'installed',
  name    => 'python-nova',
  require => 'Package[python-greenlet]',
  tag     => 'openstack',
}

package { 'python-numpy':
  ensure => 'present',
  name   => 'python-numpy',
}

service { 'nova-api':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'nova-api',
  require   => 'Package[nova-common]',
  tag       => 'nova-service',
}

service { 'nova-cert':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'nova-cert',
  require   => 'Package[nova-common]',
  tag       => 'nova-service',
}

service { 'nova-conductor':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'nova-conductor',
  require   => 'Package[nova-common]',
  tag       => 'nova-service',
}

service { 'nova-consoleauth':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'nova-consoleauth',
  require   => 'Package[nova-common]',
  tag       => 'nova-service',
}

service { 'nova-objectstore':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'nova-objectstore',
  require   => 'Package[nova-common]',
  tag       => 'nova-service',
}

service { 'nova-scheduler':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'nova-scheduler',
  require   => 'Package[nova-common]',
  tag       => 'nova-service',
}

service { 'nova-vncproxy':
  ensure    => 'running',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'nova-novncproxy',
  require   => 'Package[nova-common]',
  tag       => 'nova-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'nova-api':
  name         => 'nova-api',
  package_name => 'nova-api',
  service_name => 'nova-api',
}

tweaks::ubuntu_service_override { 'nova-cells':
  name         => 'nova-cells',
  package_name => 'nova-cells',
  service_name => 'nova-cells',
}

tweaks::ubuntu_service_override { 'nova-cert':
  name         => 'nova-cert',
  package_name => 'nova-cert',
  service_name => 'nova-cert',
}

tweaks::ubuntu_service_override { 'nova-conductor':
  name         => 'nova-conductor',
  package_name => 'nova-conductor',
  service_name => 'nova-conductor',
}

tweaks::ubuntu_service_override { 'nova-consoleauth':
  name         => 'nova-consoleauth',
  package_name => 'nova-consoleauth',
  service_name => 'nova-consoleauth',
}

tweaks::ubuntu_service_override { 'nova-consoleproxy':
  name         => 'nova-consoleproxy',
  package_name => 'nova-consoleproxy',
  service_name => 'nova-consoleproxy',
}

tweaks::ubuntu_service_override { 'nova-objectstore':
  name         => 'nova-objectstore',
  package_name => 'nova-objectstore',
  service_name => 'nova-objectstore',
}

tweaks::ubuntu_service_override { 'nova-scheduler':
  name         => 'nova-scheduler',
  package_name => 'nova-scheduler',
  service_name => 'nova-scheduler',
}

tweaks::ubuntu_service_override { 'nova-spicehtml5proxy':
  name         => 'nova-spicehtml5proxy',
  package_name => 'nova-spicehtml5proxy',
  service_name => 'nova-spicehtml5proxy',
}

tweaks::ubuntu_service_override { 'nova-spiceproxy':
  name         => 'nova-spiceproxy',
  package_name => 'nova-spiceproxy',
  service_name => 'nova-spiceproxy',
}

tweaks::ubuntu_service_override { 'nova-vncproxy':
  name         => 'nova-vncproxy',
  package_name => 'nova-vncproxy',
  service_name => 'nova-vncproxy',
}

