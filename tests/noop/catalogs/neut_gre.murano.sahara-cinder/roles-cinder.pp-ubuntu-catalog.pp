anchor { 'cinder-start':
  name => 'cinder-start',
}

cinder::backend::iscsi { 'DEFAULT':
  extra_options       => {},
  iscsi_helper        => 'tgtadm',
  iscsi_ip_address    => '192.168.1.1',
  iscsi_protocol      => 'iscsi',
  name                => 'DEFAULT',
  volume_backend_name => 'DEFAULT',
  volume_driver       => 'cinder.volume.drivers.lvm.LVMVolumeDriver',
  volume_group        => 'cinder',
  volumes_dir         => '/var/lib/cinder/volumes',
}

cinder_config { 'DEFAULT/amqp_durable_queues':
  name   => 'DEFAULT/amqp_durable_queues',
  notify => 'Service[cinder-volume]',
  value  => 'false',
}

cinder_config { 'DEFAULT/api_paste_config':
  name   => 'DEFAULT/api_paste_config',
  notify => 'Service[cinder-volume]',
  value  => '/etc/cinder/api-paste.ini',
}

cinder_config { 'DEFAULT/auth_strategy':
  name   => 'DEFAULT/auth_strategy',
  notify => 'Service[cinder-volume]',
  value  => 'keystone',
}

cinder_config { 'DEFAULT/control_exchange':
  name   => 'DEFAULT/control_exchange',
  notify => 'Service[cinder-volume]',
  value  => 'cinder',
}

cinder_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => 'Service[cinder-volume]',
  value  => 'false',
}

cinder_config { 'DEFAULT/default_availability_zone':
  name   => 'DEFAULT/default_availability_zone',
  notify => 'Service[cinder-volume]',
  value  => 'nova',
}

cinder_config { 'DEFAULT/enable_v1_api':
  name   => 'DEFAULT/enable_v1_api',
  notify => 'Service[cinder-volume]',
  value  => 'true',
}

cinder_config { 'DEFAULT/enable_v2_api':
  name   => 'DEFAULT/enable_v2_api',
  notify => 'Service[cinder-volume]',
  value  => 'true',
}

cinder_config { 'DEFAULT/glance_api_insecure':
  name   => 'DEFAULT/glance_api_insecure',
  notify => 'Service[cinder-volume]',
  value  => 'false',
}

cinder_config { 'DEFAULT/glance_api_servers':
  name   => 'DEFAULT/glance_api_servers',
  notify => 'Service[cinder-volume]',
  value  => '192.168.0.2:9292',
}

cinder_config { 'DEFAULT/glance_api_ssl_compression':
  name   => 'DEFAULT/glance_api_ssl_compression',
  notify => 'Service[cinder-volume]',
  value  => 'false',
}

cinder_config { 'DEFAULT/glance_api_version':
  name   => 'DEFAULT/glance_api_version',
  notify => 'Service[cinder-volume]',
  value  => '2',
}

cinder_config { 'DEFAULT/glance_num_retries':
  name   => 'DEFAULT/glance_num_retries',
  notify => 'Service[cinder-volume]',
  value  => '0',
}

cinder_config { 'DEFAULT/glance_request_timeout':
  name   => 'DEFAULT/glance_request_timeout',
  notify => 'Service[cinder-volume]',
}

cinder_config { 'DEFAULT/iscsi_helper':
  name   => 'DEFAULT/iscsi_helper',
  notify => 'Service[cinder-volume]',
  value  => 'tgtadm',
}

cinder_config { 'DEFAULT/iscsi_ip_address':
  name   => 'DEFAULT/iscsi_ip_address',
  notify => 'Service[cinder-volume]',
  value  => '192.168.1.1',
}

cinder_config { 'DEFAULT/iscsi_protocol':
  name   => 'DEFAULT/iscsi_protocol',
  notify => 'Service[cinder-volume]',
  value  => 'iscsi',
}

cinder_config { 'DEFAULT/kombu_reconnect_delay':
  name   => 'DEFAULT/kombu_reconnect_delay',
  notify => 'Service[cinder-volume]',
  value  => '5.0',
}

cinder_config { 'DEFAULT/lock_path':
  name   => 'DEFAULT/lock_path',
  notify => 'Service[cinder-volume]',
  value  => '/var/lock/cinder',
}

cinder_config { 'DEFAULT/log_dir':
  name   => 'DEFAULT/log_dir',
  notify => 'Service[cinder-volume]',
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'DEFAULT/rpc_backend':
  name   => 'DEFAULT/rpc_backend',
  notify => 'Service[cinder-volume]',
  value  => 'cinder.openstack.common.rpc.impl_kombu',
}

cinder_config { 'DEFAULT/ssl_ca_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_ca_file',
  notify => 'Service[cinder-volume]',
}

cinder_config { 'DEFAULT/ssl_cert_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_cert_file',
  notify => 'Service[cinder-volume]',
}

cinder_config { 'DEFAULT/ssl_key_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_key_file',
  notify => 'Service[cinder-volume]',
}

cinder_config { 'DEFAULT/storage_availability_zone':
  name   => 'DEFAULT/storage_availability_zone',
  notify => 'Service[cinder-volume]',
  value  => 'nova',
}

cinder_config { 'DEFAULT/syslog_log_facility':
  name   => 'DEFAULT/syslog_log_facility',
  notify => 'Service[cinder-volume]',
  value  => 'LOG_LOCAL3',
}

cinder_config { 'DEFAULT/use_stderr':
  name   => 'DEFAULT/use_stderr',
  notify => 'Service[cinder-volume]',
  value  => 'false',
}

cinder_config { 'DEFAULT/use_syslog':
  name   => 'DEFAULT/use_syslog',
  notify => 'Service[cinder-volume]',
  value  => 'true',
}

cinder_config { 'DEFAULT/use_syslog_rfc_format':
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => 'Service[cinder-volume]',
  value  => 'true',
}

cinder_config { 'DEFAULT/verbose':
  name   => 'DEFAULT/verbose',
  notify => 'Service[cinder-volume]',
  value  => 'true',
}

cinder_config { 'DEFAULT/volume_backend_name':
  name   => 'DEFAULT/volume_backend_name',
  notify => 'Service[cinder-volume]',
  value  => 'DEFAULT',
}

cinder_config { 'DEFAULT/volume_driver':
  name   => 'DEFAULT/volume_driver',
  notify => 'Service[cinder-volume]',
  value  => 'cinder.volume.drivers.lvm.LVMVolumeDriver',
}

cinder_config { 'DEFAULT/volume_group':
  name   => 'DEFAULT/volume_group',
  notify => 'Service[cinder-volume]',
  value  => 'cinder',
}

cinder_config { 'DEFAULT/volumes_dir':
  name   => 'DEFAULT/volumes_dir',
  notify => 'Service[cinder-volume]',
  value  => '/var/lib/cinder/volumes',
}

cinder_config { 'database/connection':
  name   => 'database/connection',
  notify => 'Service[cinder-volume]',
  secret => 'true',
  value  => 'mysql://cinder:71kNkN9U@192.168.0.2/cinder?charset=utf8&read_timeout=60',
}

cinder_config { 'database/idle_timeout':
  name   => 'database/idle_timeout',
  notify => 'Service[cinder-volume]',
  value  => '3600',
}

cinder_config { 'database/max_overflow':
  name   => 'database/max_overflow',
  notify => 'Service[cinder-volume]',
  value  => '20',
}

cinder_config { 'database/max_pool_size':
  name   => 'database/max_pool_size',
  notify => 'Service[cinder-volume]',
  value  => '20',
}

cinder_config { 'database/max_retries':
  name   => 'database/max_retries',
  notify => 'Service[cinder-volume]',
  value  => '-1',
}

cinder_config { 'database/min_pool_size':
  name   => 'database/min_pool_size',
  notify => 'Service[cinder-volume]',
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'database/retry_interval':
  name   => 'database/retry_interval',
  notify => 'Service[cinder-volume]',
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'keymgr/fixed_key':
  name   => 'keymgr/fixed_key',
  notify => 'Service[cinder-volume]',
  value  => '0ded0202e2a355df942df2bacbaba992658a0345f68f2db6e1bdb6dbb8f682cf',
}

cinder_config { 'keystone_authtoken/admin_password':
  name   => 'keystone_authtoken/admin_password',
  notify => 'Service[cinder-volume]',
  value  => 'O2st17AP',
}

cinder_config { 'keystone_authtoken/admin_tenant_name':
  name   => 'keystone_authtoken/admin_tenant_name',
  notify => 'Service[cinder-volume]',
  value  => 'services',
}

cinder_config { 'keystone_authtoken/admin_user':
  name   => 'keystone_authtoken/admin_user',
  notify => 'Service[cinder-volume]',
  value  => 'cinder',
}

cinder_config { 'keystone_authtoken/auth_uri':
  name   => 'keystone_authtoken/auth_uri',
  notify => 'Service[cinder-volume]',
  value  => 'http://192.168.0.2:5000/',
}

cinder_config { 'keystone_authtoken/identity_uri':
  name   => 'keystone_authtoken/identity_uri',
  notify => 'Service[cinder-volume]',
  value  => 'http://192.168.0.2:5000/',
}

cinder_config { 'keystone_authtoken/signing_dir':
  name   => 'keystone_authtoken/signing_dir',
  notify => 'Service[cinder-volume]',
  value  => '/tmp/keystone-signing-cinder',
}

cinder_config { 'keystone_authtoken/signing_dirname':
  name   => 'keystone_authtoken/signing_dirname',
  notify => 'Service[cinder-volume]',
  value  => '/tmp/keystone-signing-cinder',
}

cinder_config { 'oslo_messaging_rabbit/heartbeat_rate':
  name   => 'oslo_messaging_rabbit/heartbeat_rate',
  notify => 'Service[cinder-volume]',
  value  => '2',
}

cinder_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold':
  name   => 'oslo_messaging_rabbit/heartbeat_timeout_threshold',
  notify => 'Service[cinder-volume]',
  value  => '0',
}

cinder_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs':
  name   => 'oslo_messaging_rabbit/kombu_ssl_ca_certs',
  notify => 'Service[cinder-volume]',
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'oslo_messaging_rabbit/kombu_ssl_certfile':
  name   => 'oslo_messaging_rabbit/kombu_ssl_certfile',
  notify => 'Service[cinder-volume]',
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile':
  name   => 'oslo_messaging_rabbit/kombu_ssl_keyfile',
  notify => 'Service[cinder-volume]',
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'oslo_messaging_rabbit/kombu_ssl_version':
  name   => 'oslo_messaging_rabbit/kombu_ssl_version',
  notify => 'Service[cinder-volume]',
  value  => '<SERVICE DEFAULT>',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  before => 'Service[cinder-volume]',
  name   => 'oslo_messaging_rabbit/rabbit_ha_queues',
  notify => 'Service[cinder-volume]',
  value  => 'true',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_host':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/rabbit_host',
  notify => 'Service[cinder-volume]',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_hosts':
  name   => 'oslo_messaging_rabbit/rabbit_hosts',
  notify => 'Service[cinder-volume]',
  value  => '192.168.0.3:5673, 192.168.0.4:5673, 192.168.0.2:5673',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_password':
  name   => 'oslo_messaging_rabbit/rabbit_password',
  notify => 'Service[cinder-volume]',
  secret => 'true',
  value  => 'c7fQJeSe',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_port':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/rabbit_port',
  notify => 'Service[cinder-volume]',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_use_ssl':
  name   => 'oslo_messaging_rabbit/rabbit_use_ssl',
  notify => 'Service[cinder-volume]',
  value  => 'false',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_userid':
  name   => 'oslo_messaging_rabbit/rabbit_userid',
  notify => 'Service[cinder-volume]',
  value  => 'nova',
}

cinder_config { 'oslo_messaging_rabbit/rabbit_virtual_host':
  name   => 'oslo_messaging_rabbit/rabbit_virtual_host',
  notify => 'Service[cinder-volume]',
  value  => '/',
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

class { 'Cinder::Volume::Iscsi':
  extra_options    => {},
  iscsi_helper     => 'tgtadm',
  iscsi_ip_address => '192.168.1.1',
  iscsi_protocol   => 'iscsi',
  name             => 'Cinder::Volume::Iscsi',
  volume_driver    => 'cinder.volume.drivers.lvm.LVMVolumeDriver',
  volume_group     => 'cinder',
  volumes_dir      => '/var/lib/cinder/volumes',
}

class { 'Cinder::Volume':
  enabled        => 'false',
  manage_service => 'true',
  name           => 'Cinder::Volume',
  package_ensure => 'installed',
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
  rabbit_hosts                       => ['192.168.0.3:5673', ' 192.168.0.4:5673', ' 192.168.0.2:5673'],
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

class { 'Keystone::Params':
  name => 'Keystone::Params',
}

class { 'Keystone::Python':
  ensure              => 'present',
  client_package_name => 'python-keystone',
  name                => 'Keystone::Python',
}

class { 'Mellanox_openstack::Cinder':
  iser            => 'false',
  iser_ip_address => '192.168.1.1',
  name            => 'Mellanox_openstack::Cinder',
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
  amqp_hosts           => '192.168.0.3:5673, 192.168.0.4:5673, 192.168.0.2:5673',
  amqp_password        => 'c7fQJeSe',
  amqp_user            => 'nova',
  auth_host            => '192.168.0.2',
  auth_uri             => 'http://192.168.0.2:5000/',
  bind_host            => 'false',
  ceilometer           => 'false',
  cinder_user_password => 'O2st17AP',
  debug                => 'false',
  enable_volumes       => 'false',
  enabled              => 'true',
  glance_api_servers   => '192.168.0.2:9292',
  identity_uri         => 'http://192.168.0.2:5000/',
  idle_timeout         => '3600',
  iscsi_bind_host      => '192.168.1.1',
  iser                 => 'false',
  keystone_enabled     => 'true',
  keystone_tenant      => 'services',
  keystone_user        => 'cinder',
  manage_volumes       => 'iscsi',
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

exec { 'remove_cinder-volume_override':
  before    => ['Service[cinder-volume]', 'Service[cinder-volume]'],
  command   => 'rm -f /etc/init/cinder-volume.override',
  logoutput => 'true',
  onlyif    => 'test -f /etc/init/cinder-volume.override',
  path      => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { 'create_cinder-volume_override':
  ensure  => 'present',
  before  => ['Package[cinder-volume]', 'Package[cinder-volume]', 'Exec[remove_cinder-volume_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/cinder-volume.override',
}

package { 'cinder-volume':
  ensure => 'installed',
  before => ['Service[cinder-volume]', 'Exec[remove_cinder-volume_override]', 'Exec[remove_cinder-volume_override]'],
  name   => 'cinder-volume',
  tag    => ['openstack', 'cinder-package'],
}

package { 'cinder':
  ensure  => 'installed',
  before  => 'Package[cinder-volume]',
  name    => 'cinder-common',
  require => 'Anchor[cinder-start]',
  tag     => ['openstack', 'cinder-package'],
}

package { 'python-amqp':
  ensure => 'present',
  name   => 'python-amqp',
}

package { 'python-keystone':
  ensure => 'present',
  name   => 'python-keystone',
}

package { 'python-mysqldb':
  ensure => 'present',
  name   => 'python-mysqldb',
}

package { 'tgt':
  ensure => 'present',
  name   => 'tgt',
}

service { 'cinder-volume':
  ensure    => 'stopped',
  enable    => 'false',
  hasstatus => 'true',
  name      => 'cinder-volume',
  require   => 'Package[cinder]',
  tag       => 'cinder-service',
}

service { 'tgtd':
  ensure  => 'running',
  enable  => 'true',
  name    => 'tgt',
  require => 'Class[Cinder::Volume]',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'cinder-volume':
  name         => 'cinder-volume',
  package_name => 'cinder-volume',
  service_name => 'cinder-volume',
}

