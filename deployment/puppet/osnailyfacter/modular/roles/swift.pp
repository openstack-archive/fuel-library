import '../globals.pp'

$swift_zone = $node[0]['swift_zone']

class { 'openstack::swift::storage_node' :
  storage_type               => $swift_loopback,
  loopback_size              => '5243780',
  storage_mnt_base_dir       => $swift_partition,
  storage_devices            => $mountpoints,
  swift_zone                 => $swift_zone,
  swift_local_net_ip         => $swift_local_net_ip,
  master_swift_proxy_ip      => $master_swift_proxy_ip,
  cinder                     => $cinder,
  cinder_iscsi_bind_addr     => $cinder_iscsi_bind_addr,
  cinder_volume_group        => 'cinder',
  manage_volumes             => $manage_volumes,
  db_host                    => hiera('management_vip'),
  service_endpoint           => hiera('management_vip'),
  cinder_rate_limits         => $cinder_rate_limits,
  queue_provider             => $queue_provider,
  rabbit_nodes               => $controller_nodes,
  rabbit_password            => $rabbit_hash['password'],
  rabbit_user                => $rabbit_hash['user'],
  rabbit_ha_virtual_ip       => hiera('management_vip'),
  qpid_password              => $rabbit_hash['password'],
  qpid_user                  => $rabbit_hash['user'],
  qpid_nodes                 => [ hiera('management_vip') ],
  sync_rings                 => ! $primary_proxy,
  syslog_log_level           => $syslog_log_level,
  debug                      => $debug,
  verbose                    => $verbose,
  syslog_log_facility_cinder => $syslog_log_facility_cinder,
  log_facility               => 'LOG_SYSLOG',
}
