anchor { 'nova-start':
  name => 'nova-start',
}

augeas { 'default-libvirt':
  before  => 'Augeas[libvirt-conf]',
  changes => 'set libvirtd_opts '"-l -d"'',
  context => '/files/etc/default/libvirt-bin',
  name    => 'default-libvirt',
}

augeas { 'libvirt-conf-uuid':
  changes => 'set host_uuid 2cb60443-d9c4-46c0-86da-918c4dd20987
',
  context => '/files/etc/libvirt/libvirtd.conf',
  name    => 'libvirt-conf-uuid',
  notify  => 'Service[libvirt]',
  onlyif  => 'match /files/etc/libvirt/libvirtd.conf/host_uuid size == 0',
}

augeas { 'libvirt-conf':
  changes => ['set listen_tls 0', 'set listen_tcp 1', 'set auth_tcp none'],
  context => '/files/etc/libvirt/libvirtd.conf',
  name    => 'libvirt-conf',
  notify  => 'Service[libvirt]',
}

class { 'Nova::Client':
  ensure => 'present',
  name   => 'Nova::Client',
}

class { 'Nova::Compute::Libvirt':
  compute_driver                             => 'libvirt.LibvirtDriver',
  libvirt_cpu_mode                           => 'host-model',
  libvirt_disk_cachemodes                    => '"file=directsync,block=none"',
  libvirt_inject_key                         => 'false',
  libvirt_inject_partition                   => '1',
  libvirt_inject_password                    => 'false',
  libvirt_service_name                       => 'libvirtd',
  libvirt_virt_type                          => 'qemu',
  migration_support                          => 'true',
  name                                       => 'Nova::Compute::Libvirt',
  remove_unused_original_minimum_age_seconds => '86400',
  vncserver_listen                           => '0.0.0.0',
}

class { 'Nova::Compute':
  compute_manager                    => 'nova.compute.manager.ComputeManager',
  config_drive_format                => 'vfat',
  default_availability_zone          => 'nova',
  enabled                            => 'false',
  ensure_package                     => 'installed',
  force_config_drive                 => 'false',
  force_raw_images                   => 'true',
  heal_instance_info_cache_interval  => '60',
  install_bridge_utils               => 'false',
  instance_usage_audit               => 'true',
  instance_usage_audit_period        => 'hour',
  internal_service_availability_zone => 'internal',
  manage_service                     => 'true',
  name                               => 'Nova::Compute',
  neutron_enabled                    => 'true',
  reserved_host_memory               => '512',
  virtio_nic                         => 'false',
  vnc_enabled                        => 'true',
  vnc_keymap                         => 'en-us',
  vncproxy_host                      => 'public.fuel.local',
  vncproxy_path                      => '/vnc_auto.html',
  vncproxy_port                      => '6080',
  vncproxy_protocol                  => 'https',
  vncserver_proxyclient_address      => '192.168.0.5',
}

class { 'Nova::Config':
  name               => 'Nova::Config',
  nova_config        => {'DEFAULT/block_device_allocate_retries' => {'value' => '300'}, 'DEFAULT/block_device_allocate_retries_interval' => {'value' => '3'}, 'DEFAULT/resume_guests_state_on_host_boot' => {'value' => 'true'}, 'DEFAULT/use_cow_images' => {'value' => 'true'}, 'libvirt/libvirt_inject_key' => {'value' => 'true'}, 'libvirt/libvirt_inject_password' => {'value' => 'true'}},
  nova_paste_api_ini => {},
}

class { 'Nova::Db':
  name => 'Nova::Db',
}

class { 'Nova::Migration::Libvirt':
  auth    => 'none',
  name    => 'Nova::Migration::Libvirt',
  use_tls => 'false',
}

class { 'Nova::Params':
  name => 'Nova::Params',
}

class { 'Nova::Vncproxy::Common':
  name => 'Nova::Vncproxy::Common',
}

class { 'Nova':
  amqp_durable_queues                => 'false',
  auth_strategy                      => 'keystone',
  ca_file                            => 'false',
  cert_file                          => 'false',
  database_connection                => 'false',
  database_idle_timeout              => '3600',
  debug                              => 'false',
  enabled_ssl_apis                   => ['ec2', 'metadata', 'osapi_compute'],
  ensure_package                     => 'installed',
  glance_api_servers                 => '192.168.0.2:9292',
  image_service                      => 'nova.image.glance.GlanceImageService',
  install_utilities                  => 'false',
  key_file                           => 'false',
  kombu_reconnect_delay              => '5.0',
  kombu_ssl_version                  => 'TLSv1',
  lock_path                          => '/var/lock/nova',
  log_dir                            => '/var/log/nova',
  log_facility                       => 'LOG_LOCAL6',
  memcached_servers                  => ['192.168.0.2:11211', '192.168.0.3:11211', '192.168.0.4:11211'],
  name                               => 'Nova',
  notification_driver                => [],
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
  rabbit_hosts                       => ['192.168.0.2:5673', ' 192.168.0.3:5673', ' 192.168.0.4:5673'],
  rabbit_password                    => 'c7fQJeSe',
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

class { 'Openstack::Compute':
  amqp_hosts                     => '192.168.0.2:5673, 192.168.0.3:5673, 192.168.0.4:5673',
  amqp_password                  => 'c7fQJeSe',
  amqp_user                      => 'nova',
  auto_assign_floating_ip        => 'false',
  base_mac                       => 'fa:16:3e:00:00:00',
  cache_server_ip                => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  cache_server_port              => '11211',
  ceilometer                     => 'false',
  ceilometer_metering_secret     => '7aqxzabx',
  ceilometer_user_password       => 'FQUfTQ6a',
  cinder                         => 'true',
  cinder_db_dbname               => 'cinder',
  cinder_db_password             => '71kNkN9U',
  cinder_db_user                 => 'cinder',
  cinder_iscsi_bind_addr         => '192.168.1.5',
  cinder_user_password           => 'O2st17AP',
  cinder_volume_group            => 'cinder',
  compute_driver                 => 'libvirt.LibvirtDriver',
  config_drive_format            => 'vfat',
  create_networks                => 'false',
  database_connection            => 'false',
  db_host                        => '192.168.0.2',
  debug                          => 'false',
  enabled                        => 'false',
  fixed_range                    => 'false',
  glance_api_servers             => '192.168.0.2:9292',
  install_bridge_utils           => 'false',
  internal_address               => '192.168.0.5',
  libvirt_type                   => 'qemu',
  libvirt_vif_driver             => 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver',
  manage_volumes                 => 'false',
  migration_support              => 'true',
  multi_host                     => 'true',
  name                           => 'Openstack::Compute',
  network_config                 => {},
  network_manager                => '',
  network_provider               => 'neutron',
  neutron_integration_bridge     => 'br-int',
  neutron_settings               => {'L2' => {'base_mac' => 'fa:16:3e:00:00:00', 'phys_nets' => {}, 'segmentation_type' => 'tun', 'tunnel_id_ranges' => '2:65535'}, 'L3' => {'use_namespaces' => 'true'}, 'database' => {'passwd' => 'QRpCfPk8'}, 'keystone' => {'admin_password' => 'oT56DSZF'}, 'metadata' => {'metadata_proxy_shared_secret' => 'fp618p5V'}, 'predefined_networks' => {'net04' => {'L2' => {'network_type' => 'gre', 'physnet' => '', 'router_ext' => 'false', 'segment_id' => ''}, 'L3' => {'enable_dhcp' => 'true', 'floating' => '', 'gateway' => '192.168.111.1', 'nameservers' => ['8.8.4.4', '8.8.8.8'], 'subnet' => '192.168.111.0/24'}, 'shared' => 'false', 'tenant' => 'admin'}, 'net04_ext' => {'L2' => {'network_type' => 'local', 'physnet' => '', 'router_ext' => 'true', 'segment_id' => ''}, 'L3' => {'enable_dhcp' => 'false', 'floating' => '172.16.0.130:172.16.0.254', 'gateway' => '172.16.0.1', 'nameservers' => [], 'subnet' => '172.16.0.0/24'}, 'shared' => 'false', 'tenant' => 'admin'}}},
  neutron_user_password          => 'oT56DSZF',
  nova_hash                      => {'db_password' => 'mqnsUMgC', 'state_path' => '/var/lib/nova', 'user_password' => 'fj4wVCEs', 'vncproxy_protocol' => 'https'},
  nova_rate_limits               => {'DELETE' => '100000', 'GET' => '100000', 'POST' => '100000', 'POST_SERVERS' => '100000', 'PUT' => '1000'},
  nova_report_interval           => '60',
  nova_service_down_time         => '180',
  nova_user_password             => 'fj4wVCEs',
  private_interface              => 'false',
  public_interface               => '',
  purge_nova_config              => 'false',
  queue_provider                 => 'rabbitmq',
  rabbit_ha_queues               => 'false',
  rpc_backend                    => 'nova.openstack.common.rpc.impl_kombu',
  service_endpoint               => '192.168.0.2',
  ssh_private_key                => '/var/lib/astute/nova/nova',
  ssh_public_key                 => '/var/lib/astute/nova/nova.pub',
  state_path                     => '/var/lib/nova',
  storage_hash                   => {'ephemeral_ceph' => 'false', 'images_ceph' => 'false', 'images_vcenter' => 'false', 'iser' => 'false', 'metadata' => {'label' => 'Storage', 'weight' => '60'}, 'objects_ceph' => 'false', 'osd_pool_size' => '2', 'pg_num' => '128', 'volumes_ceph' => 'false', 'volumes_lvm' => 'true'},
  syslog_log_facility            => 'LOG_LOCAL6',
  syslog_log_facility_ceilometer => 'LOG_LOCAL0',
  syslog_log_facility_neutron    => 'LOG_LOCAL4',
  use_stderr                     => 'false',
  use_syslog                     => 'true',
  verbose                        => 'true',
  vnc_enabled                    => 'true',
  vncproxy_host                  => 'public.fuel.local',
  vncserver_listen               => '0.0.0.0',
}

class { 'Osnailyfacter::Test_compute':
  name => 'Osnailyfacter::Test_compute',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'networking-refresh':
  command     => '/sbin/ifdown -a ; /sbin/ifup -a',
  logoutput   => 'true',
  refreshonly => 'true',
}

exec { 'post-nova_config':
  command     => '/bin/echo "Nova config has changed"',
  logoutput   => 'true',
  notify      => 'Service[nova-compute]',
  refreshonly => 'true',
}

exec { 'remove_nova-compute_override':
  before    => ['Service[nova-compute]', 'Service[nova-compute]'],
  command   => 'rm -f /etc/init/nova-compute.override',
  logoutput => 'true',
  onlyif    => 'test -f /etc/init/nova-compute.override',
  path      => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/etc/default/cpufrequtils':
  content => 'GOVERNOR="performance" 
',
  notify  => 'Service[cpufrequtils]',
  path    => '/etc/default/cpufrequtils',
  require => 'Package[cpufrequtils]',
}

file { '/etc/nova/nova.conf':
  group   => 'nova',
  mode    => '0640',
  owner   => 'nova',
  path    => '/etc/nova/nova.conf',
  require => 'Package[nova-common]',
}

file { '/tmp/compute-file':
  content => 'Hello world!  is installed',
  path    => '/tmp/compute-file',
}

file { '/var/lib/nova/.ssh/config':
  ensure  => 'present',
  content => 'Host *
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
',
  group   => 'nova',
  mode    => '0600',
  owner   => 'nova',
  path    => '/var/lib/nova/.ssh/config',
}

file { '/var/log/nova':
  ensure  => 'directory',
  group   => 'adm',
  mode    => '0750',
  owner   => 'nova',
  path    => '/var/log/nova',
  require => 'Package[nova-common]',
}

file { 'create_nova-compute_override':
  ensure  => 'present',
  before  => ['Package[nova-compute-qemu]', 'Exec[remove_nova-compute_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-compute.override',
}

file_line { '/etc/default/libvirtd libvirtd opts':
  line   => 'libvirtd_opts="-d -l"',
  match  => 'libvirtd_opts=',
  name   => '/etc/default/libvirtd libvirtd opts',
  notify => 'Service[libvirt]',
  path   => '/etc/default/libvirtd',
}

file_line { '/etc/libvirt/libvirtd.conf auth_tcp':
  line   => 'auth_tcp = "none"',
  match  => 'auth_tcp =',
  name   => '/etc/libvirt/libvirtd.conf auth_tcp',
  notify => 'Service[libvirt]',
  path   => '/etc/libvirt/libvirtd.conf',
}

file_line { '/etc/libvirt/libvirtd.conf listen_tcp':
  line   => 'listen_tcp = 1',
  match  => 'listen_tcp =',
  name   => '/etc/libvirt/libvirtd.conf listen_tcp',
  notify => 'Service[libvirt]',
  path   => '/etc/libvirt/libvirtd.conf',
}

file_line { '/etc/libvirt/libvirtd.conf listen_tls':
  line   => 'listen_tls = 0',
  match  => 'listen_tls =',
  name   => '/etc/libvirt/libvirtd.conf listen_tls',
  notify => 'Service[libvirt]',
  path   => '/etc/libvirt/libvirtd.conf',
}

file_line { 'nbd_on_boot':
  line => 'nbd',
  name => 'nbd_on_boot',
  path => '/etc/modules',
}

file_line { 'no_qemu_selinux':
  line    => 'security_driver = "none"',
  name    => 'no_qemu_selinux',
  notify  => 'Service[libvirt]',
  path    => '/etc/libvirt/qemu.conf',
  require => 'Package[libvirt-bin]',
}

install_ssh_keys { 'nova_ssh_key_for_migration':
  ensure           => 'present',
  authorized_keys  => 'authorized_keys',
  before           => 'File[/var/lib/nova/.ssh/config]',
  name             => 'nova_ssh_key_for_migration',
  private_key_name => 'id_rsa',
  private_key_path => '/var/lib/astute/nova/nova',
  public_key_name  => 'id_rsa.pub',
  public_key_path  => '/var/lib/astute/nova/nova.pub',
  user             => 'nova',
}

k_mod { 'nbd':
  ensure => 'present',
  module => 'nbd',
}

notify { 'Module openstack cannot notify service nova-compute on packages update':
  name => 'Module openstack cannot notify service nova-compute on packages update',
}

notify { 'Module openstack cannot notify service nova-computeon packages update':
  name => 'Module openstack cannot notify service nova-computeon packages update',
}

nova::generic_service { 'compute':
  before         => 'Exec[networking-refresh]',
  enabled        => 'false',
  ensure_package => 'installed',
  manage_service => 'true',
  name           => 'compute',
  package_name   => 'nova-compute',
  service_name   => 'nova-compute',
}

nova_config { 'DEFAULT/allow_resize_to_same_host':
  name   => 'DEFAULT/allow_resize_to_same_host',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/amqp_durable_queues':
  name   => 'DEFAULT/amqp_durable_queues',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'DEFAULT/auth_strategy':
  name   => 'DEFAULT/auth_strategy',
  notify => 'Exec[post-nova_config]',
  value  => 'keystone',
}

nova_config { 'DEFAULT/block_device_allocate_retries':
  name   => 'DEFAULT/block_device_allocate_retries',
  notify => 'Exec[post-nova_config]',
  value  => '300',
}

nova_config { 'DEFAULT/block_device_allocate_retries_interval':
  name   => 'DEFAULT/block_device_allocate_retries_interval',
  notify => 'Exec[post-nova_config]',
  value  => '3',
}

nova_config { 'DEFAULT/compute_driver':
  name   => 'DEFAULT/compute_driver',
  notify => 'Exec[post-nova_config]',
  value  => 'libvirt.LibvirtDriver',
}

nova_config { 'DEFAULT/compute_manager':
  name   => 'DEFAULT/compute_manager',
  notify => 'Exec[post-nova_config]',
  value  => 'nova.compute.manager.ComputeManager',
}

nova_config { 'DEFAULT/config_drive_format':
  name   => 'DEFAULT/config_drive_format',
  notify => 'Exec[post-nova_config]',
  value  => 'vfat',
}

nova_config { 'DEFAULT/connection_type':
  name   => 'DEFAULT/connection_type',
  notify => 'Exec[post-nova_config]',
  value  => 'libvirt',
}

nova_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'DEFAULT/default_availability_zone':
  name   => 'DEFAULT/default_availability_zone',
  notify => 'Exec[post-nova_config]',
  value  => 'nova',
}

nova_config { 'DEFAULT/enabled_ssl_apis':
  ensure => 'absent',
  name   => 'DEFAULT/enabled_ssl_apis',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/force_config_drive':
  ensure => 'absent',
  name   => 'DEFAULT/force_config_drive',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/force_raw_images':
  name   => 'DEFAULT/force_raw_images',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/heal_instance_info_cache_interval':
  name   => 'DEFAULT/heal_instance_info_cache_interval',
  notify => 'Exec[post-nova_config]',
  value  => '60',
}

nova_config { 'DEFAULT/image_service':
  name   => 'DEFAULT/image_service',
  notify => 'Exec[post-nova_config]',
  value  => 'nova.image.glance.GlanceImageService',
}

nova_config { 'DEFAULT/instance_usage_audit':
  name   => 'DEFAULT/instance_usage_audit',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/instance_usage_audit_period':
  name   => 'DEFAULT/instance_usage_audit_period',
  notify => 'Exec[post-nova_config]',
  value  => 'hour',
}

nova_config { 'DEFAULT/internal_service_availability_zone':
  name   => 'DEFAULT/internal_service_availability_zone',
  notify => 'Exec[post-nova_config]',
  value  => 'internal',
}

nova_config { 'DEFAULT/lock_path':
  name   => 'DEFAULT/lock_path',
  notify => 'Exec[post-nova_config]',
  value  => '/var/lock/nova',
}

nova_config { 'DEFAULT/log_dir':
  name   => 'DEFAULT/log_dir',
  notify => 'Exec[post-nova_config]',
  value  => '/var/log/nova',
}

nova_config { 'DEFAULT/memcached_servers':
  name   => 'DEFAULT/memcached_servers',
  notify => 'Exec[post-nova_config]',
  value  => '192.168.0.2:11211,192.168.0.3:11211,192.168.0.4:11211',
}

nova_config { 'DEFAULT/network_device_mtu':
  ensure => 'absent',
  name   => 'DEFAULT/network_device_mtu',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/notification_driver':
  name   => 'DEFAULT/notification_driver',
  notify => 'Exec[post-nova_config]',
  value  => '',
}

nova_config { 'DEFAULT/notification_topics':
  name   => 'DEFAULT/notification_topics',
  notify => 'Exec[post-nova_config]',
  value  => 'notifications',
}

nova_config { 'DEFAULT/notify_api_faults':
  name   => 'DEFAULT/notify_api_faults',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'DEFAULT/notify_on_state_change':
  name   => 'DEFAULT/notify_on_state_change',
  notify => 'Exec[post-nova_config]',
  value  => 'vm_and_task_state',
}

nova_config { 'DEFAULT/novncproxy_base_url':
  name   => 'DEFAULT/novncproxy_base_url',
  notify => 'Exec[post-nova_config]',
  value  => 'https://public.fuel.local:6080/vnc_auto.html',
}

nova_config { 'DEFAULT/os_region_name':
  ensure => 'absent',
  name   => 'DEFAULT/os_region_name',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/remove_unused_base_images':
  ensure => 'absent',
  name   => 'DEFAULT/remove_unused_base_images',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/remove_unused_original_minimum_age_seconds':
  name   => 'DEFAULT/remove_unused_original_minimum_age_seconds',
  notify => 'Exec[post-nova_config]',
  value  => '86400',
}

nova_config { 'DEFAULT/report_interval':
  name   => 'DEFAULT/report_interval',
  notify => 'Exec[post-nova_config]',
  value  => '60',
}

nova_config { 'DEFAULT/reserved_host_memory_mb':
  name   => 'DEFAULT/reserved_host_memory_mb',
  notify => 'Exec[post-nova_config]',
  value  => '512',
}

nova_config { 'DEFAULT/resume_guests_state_on_host_boot':
  name   => 'DEFAULT/resume_guests_state_on_host_boot',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/rootwrap_config':
  name   => 'DEFAULT/rootwrap_config',
  notify => 'Exec[post-nova_config]',
  value  => '/etc/nova/rootwrap.conf',
}

nova_config { 'DEFAULT/rpc_backend':
  name   => 'DEFAULT/rpc_backend',
  notify => 'Exec[post-nova_config]',
  value  => 'nova.openstack.common.rpc.impl_kombu',
}

nova_config { 'DEFAULT/service_down_time':
  name   => 'DEFAULT/service_down_time',
  notify => 'Exec[post-nova_config]',
  value  => '180',
}

nova_config { 'DEFAULT/ssl_ca_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_ca_file',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/ssl_cert_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_cert_file',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/ssl_key_file':
  ensure => 'absent',
  name   => 'DEFAULT/ssl_key_file',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'DEFAULT/state_path':
  name   => 'DEFAULT/state_path',
  notify => 'Exec[post-nova_config]',
  value  => '/var/lib/nova',
}

nova_config { 'DEFAULT/syslog_log_facility':
  name   => 'DEFAULT/syslog_log_facility',
  notify => 'Exec[post-nova_config]',
  value  => 'LOG_LOCAL6',
}

nova_config { 'DEFAULT/use_cow_images':
  name   => 'DEFAULT/use_cow_images',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/use_stderr':
  name   => 'DEFAULT/use_stderr',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'DEFAULT/use_syslog':
  name   => 'DEFAULT/use_syslog',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/use_syslog_rfc_format':
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/verbose':
  name   => 'DEFAULT/verbose',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/vnc_enabled':
  name   => 'DEFAULT/vnc_enabled',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'DEFAULT/vnc_keymap':
  name   => 'DEFAULT/vnc_keymap',
  notify => 'Exec[post-nova_config]',
  value  => 'en-us',
}

nova_config { 'DEFAULT/vncserver_listen':
  name   => 'DEFAULT/vncserver_listen',
  notify => 'Exec[post-nova_config]',
  value  => '0.0.0.0',
}

nova_config { 'DEFAULT/vncserver_proxyclient_address':
  name   => 'DEFAULT/vncserver_proxyclient_address',
  notify => 'Exec[post-nova_config]',
  value  => '192.168.0.5',
}

nova_config { 'cinder/catalog_info':
  name   => 'cinder/catalog_info',
  notify => 'Exec[post-nova_config]',
  value  => 'volume:cinder:internalURL',
}

nova_config { 'cinder/os_region_name':
  ensure => 'absent',
  name   => 'cinder/os_region_name',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'glance/api_servers':
  name   => 'glance/api_servers',
  notify => 'Exec[post-nova_config]',
  value  => '192.168.0.2:9292',
}

nova_config { 'keymgr/fixed_key':
  name   => 'keymgr/fixed_key',
  notify => 'Exec[post-nova_config]',
  value  => '0ded0202e2a355df942df2bacbaba992658a0345f68f2db6e1bdb6dbb8f682cf',
}

nova_config { 'libvirt/block_migration_flag':
  name   => 'libvirt/block_migration_flag',
  notify => 'Exec[post-nova_config]',
  value  => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_NON_SHARED_INC',
}

nova_config { 'libvirt/cpu_mode':
  name   => 'libvirt/cpu_mode',
  notify => 'Exec[post-nova_config]',
  value  => 'host-model',
}

nova_config { 'libvirt/cpu_model':
  ensure => 'absent',
  name   => 'libvirt/cpu_model',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'libvirt/disk_cachemodes':
  name   => 'libvirt/disk_cachemodes',
  notify => 'Exec[post-nova_config]',
  value  => '"file=directsync,block=none"',
}

nova_config { 'libvirt/inject_key':
  name   => 'libvirt/inject_key',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'libvirt/inject_partition':
  name   => 'libvirt/inject_partition',
  notify => 'Exec[post-nova_config]',
  value  => '1',
}

nova_config { 'libvirt/inject_password':
  name   => 'libvirt/inject_password',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'libvirt/libvirt_inject_key':
  name   => 'libvirt/libvirt_inject_key',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'libvirt/libvirt_inject_password':
  name   => 'libvirt/libvirt_inject_password',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'libvirt/live_migration_flag':
  name   => 'libvirt/live_migration_flag',
  notify => 'Exec[post-nova_config]',
  value  => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST',
}

nova_config { 'libvirt/remove_unused_kernels':
  ensure => 'absent',
  name   => 'libvirt/remove_unused_kernels',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'libvirt/remove_unused_resized_minimum_age_seconds':
  ensure => 'absent',
  name   => 'libvirt/remove_unused_resized_minimum_age_seconds',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'libvirt/virt_type':
  name   => 'libvirt/virt_type',
  notify => 'Exec[post-nova_config]',
  value  => 'qemu',
}

nova_config { 'oslo_messaging_rabbit/heartbeat_rate':
  name   => 'oslo_messaging_rabbit/heartbeat_rate',
  notify => 'Exec[post-nova_config]',
  value  => '2',
}

nova_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold':
  name   => 'oslo_messaging_rabbit/heartbeat_timeout_threshold',
  notify => 'Exec[post-nova_config]',
  value  => '0',
}

nova_config { 'oslo_messaging_rabbit/kombu_reconnect_delay':
  name   => 'oslo_messaging_rabbit/kombu_reconnect_delay',
  notify => 'Exec[post-nova_config]',
  value  => '5.0',
}

nova_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_ca_certs',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'oslo_messaging_rabbit/kombu_ssl_certfile':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_certfile',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_keyfile',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'oslo_messaging_rabbit/kombu_ssl_version':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_version',
  notify => 'Exec[post-nova_config]',
}

nova_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  name   => 'oslo_messaging_rabbit/rabbit_ha_queues',
  notify => 'Exec[post-nova_config]',
  value  => 'true',
}

nova_config { 'oslo_messaging_rabbit/rabbit_hosts':
  name   => 'oslo_messaging_rabbit/rabbit_hosts',
  notify => 'Exec[post-nova_config]',
  value  => '192.168.0.2:5673, 192.168.0.3:5673, 192.168.0.4:5673',
}

nova_config { 'oslo_messaging_rabbit/rabbit_password':
  name   => 'oslo_messaging_rabbit/rabbit_password',
  notify => 'Exec[post-nova_config]',
  secret => 'true',
  value  => 'c7fQJeSe',
}

nova_config { 'oslo_messaging_rabbit/rabbit_use_ssl':
  name   => 'oslo_messaging_rabbit/rabbit_use_ssl',
  notify => 'Exec[post-nova_config]',
  value  => 'false',
}

nova_config { 'oslo_messaging_rabbit/rabbit_userid':
  name   => 'oslo_messaging_rabbit/rabbit_userid',
  notify => 'Exec[post-nova_config]',
  value  => 'nova',
}

nova_config { 'oslo_messaging_rabbit/rabbit_virtual_host':
  name   => 'oslo_messaging_rabbit/rabbit_virtual_host',
  notify => 'Exec[post-nova_config]',
  value  => '/',
}

package { 'cpufrequtils':
  ensure => 'present',
  name   => 'cpufrequtils',
  notify => 'Service[cpufrequtils]',
}

package { 'fping':
  ensure => 'present',
  name   => 'fping',
}

package { 'libvirt':
  ensure => 'present',
  before => ['File_line[/etc/libvirt/libvirtd.conf listen_tls]', 'File_line[/etc/libvirt/libvirtd.conf listen_tcp]', 'File_line[/etc/libvirt/libvirtd.conf auth_tcp]', 'File_line[/etc/default/libvirtd libvirtd opts]'],
  name   => 'libvirt-bin',
  notify => 'Service[libvirt]',
}

package { 'nova-common':
  ensure  => 'installed',
  name    => 'nova-common',
  require => ['Package[python-nova]', 'Anchor[nova-start]'],
  tag     => ['openstack', 'nova-package'],
}

package { 'nova-compute-qemu':
  ensure  => 'present',
  before  => ['Package[nova-compute]', 'Exec[remove_nova-compute_override]'],
  name    => 'nova-compute-qemu',
  notify  => 'Service[nova-compute]',
  require => 'Package[nova-common]',
  tag     => 'openstack',
}

package { 'nova-compute':
  ensure => 'installed',
  before => ['Service[nova-compute]', 'Service[nova-compute]'],
  name   => 'nova-compute',
  notify => ['Service[nova-compute]', 'Service[nova-compute]'],
  tag    => ['openstack', 'nova-package'],
}

package { 'openssh-client':
  ensure => 'installed',
  name   => 'openssh-client',
}

package { 'pm-utils':
  ensure => 'present',
  name   => 'pm-utils',
}

package { 'python-greenlet':
  ensure => 'present',
  name   => 'python-greenlet',
}

package { 'python-nova':
  ensure  => 'installed',
  name    => 'python-nova',
  require => 'Package[python-greenlet]',
  tag     => 'openstack',
}

package { 'python-novaclient':
  ensure => 'present',
  name   => 'python-novaclient',
  tag    => 'openstack',
}

service { 'cpufrequtils':
  ensure => 'true',
  enable => 'true',
  name   => 'cpufrequtils',
}

service { 'libvirt':
  ensure   => 'running',
  before   => 'Service[nova-compute]',
  enable   => 'true',
  name     => 'libvirtd',
  notify   => 'Service[nova-compute]',
  provider => 'upstart',
  require  => 'Package[libvirt]',
}

service { 'nova-compute':
  ensure    => 'stopped',
  enable    => 'false',
  hasstatus => 'true',
  name      => 'nova-compute',
  require   => 'Package[nova-common]',
  tag       => 'nova-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'nova-compute':
  name         => 'nova-compute',
  package_name => 'nova-compute-qemu',
  service_name => 'nova-compute',
}

