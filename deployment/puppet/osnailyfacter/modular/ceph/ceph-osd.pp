notice('MODULAR: ceph-osd.pp')

# Pulling hiera
$storage_hash              = hiera('storage', {})
$public_vip                = hiera('public_vip')
$management_vip            = hiera('management_vip')
$service_endpoint          = hiera('service_endpoint')
$use_neutron               = hiera('use_neutron', false)
$mp_hash                   = hiera('mp')
$verbose                   = pick($storage_hash['verbose'], true)
$debug                     = pick($storage_hash['debug'], hiera('debug', true))
$use_monit                 = false
$auto_assign_floating_ip   = hiera('auto_assign_floating_ip', false)
$keystone_hash             = hiera('keystone', {})
$access_hash               = hiera('access', {})
$network_scheme            = hiera_hash('network_scheme', {})
$neutron_mellanox          = hiera('neutron_mellanox', false)
$syslog_hash               = hiera('syslog', {})
$use_syslog                = hiera('use_syslog', true)
$mon_address_map           = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
$ceph_primary_monitor_node = hiera('ceph_primary_monitor_node')
$primary_mons              = keys($ceph_primary_monitor_node)
$primary_mon               = $ceph_primary_monitor_node[$primary_mons[0]]['name']
prepare_network_config($network_scheme)
$ceph_cluster_network      = get_network_role_property('ceph/replication', 'network')
$ceph_public_network       = get_network_role_property('ceph/public', 'network')
$ceph_tuning_settings      = hiera('ceph_tuning_settings', {})
$ssl_hash                  = hiera_hash('use_ssl', {})
$admin_auth_protocol       = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
$admin_auth_address        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
$admin_identity_url        = "${admin_auth_protocol}://${admin_auth_address}:35357"

class {'ceph':
  primary_mon              => $primary_mon,
  mon_hosts                => keys($mon_address_map),
  mon_ip_addresses         => values($mon_address_map),
  cluster_node_address     => $public_vip,
  osd_pool_default_size    => $storage_hash['osd_pool_size'],
  osd_pool_default_pg_num  => $storage_hash['pg_num'],
  osd_pool_default_pgp_num => $storage_hash['pg_num'],
  use_rgw                  => $storage_hash['objects_ceph'],
  rgw_keystone_url         => $admin_identity_url,
  glance_backend           => $glance_backend,
  rgw_pub_ip               => $public_vip,
  rgw_adm_ip               => $management_vip,
  rgw_int_ip               => $management_vip,
  cluster_network          => $ceph_cluster_network,
  public_network           => $ceph_public_network,
  use_syslog               => $use_syslog,
  syslog_log_level         => hiera('syslog_log_level_ceph', 'info'),
  syslog_log_facility      => hiera('syslog_log_facility_ceph','LOG_LOCAL0'),
  rgw_keystone_admin_token => $keystone_hash['admin_token'],
  ephemeral_ceph           => $storage_hash['ephemeral_ceph'],
}

if $ceph_tuning_settings != {} {
  ceph_conf {
    'global/debug_default'                    : value => $debug;
    'global/max_open_files'                   : value => $ceph_tuning_settings['max_open_files'];
    'osd/osd_mkfs_type'                       : value => $ceph_tuning_settings['osd_mkfs_type'];
    'osd/osd_mount_options_xfs'               : value => $ceph_tuning_settings['osd_mount_options_xfs'];
    'osd/osd_op_threads'                      : value => $ceph_tuning_settings['osd_op_threads'];
    'osd/filestore_queue_max_ops'             : value => $ceph_tuning_settings['filestore_queue_max_ops'];
    'osd/filestore_queue_committing_max_ops'  : value => $ceph_tuning_settings['filestore_queue_committing_max_ops'];
    'osd/journal_max_write_entries'           : value => $ceph_tuning_settings['journal_max_write_entries'];
    'osd/journal_queue_max_ops'               : value => $ceph_tuning_settings['journal_queue_max_ops'];
    'osd/objecter_inflight_ops'               : value => $ceph_tuning_settings['objecter_inflight_ops'];
    'osd/filestore_queue_max_bytes'           : value => $ceph_tuning_settings['filestore_queue_max_bytes'];
    'osd/filestore_queue_committing_max_bytes': value => $ceph_tuning_settings['filestore_queue_committing_max_bytes'];
    'osd/journal_max_write_bytes'             : value => $ceph_tuning_settings['journal_queue_max_bytes'];
    'osd/journal_queue_max_bytes'             : value => $ceph_tuning_settings['journal_queue_max_bytes'];
    'osd/ms_dispatch_throttle_bytes'          : value => $ceph_tuning_settings['ms_dispatch_throttle_bytes'];
    'osd/objecter_infilght_op_bytes'          : value => $ceph_tuning_settings['objecter_infilght_op_bytes'];
    'osd/filestore_max_sync_interval'         : value => $ceph_tuning_settings['filestore_max_sync_interval'];
  }
  # File /root/ceph.conf is symlink which is created after /etc/ceph/ceph.conf in ceph::conf class
  File<| title == '/root/ceph.conf' |> -> Ceph_conf <||>
}

# TODO(bogdando) add monit ceph-osd services monitoring, if required

#################################################################

# vim: set ts=2 sw=2 et :
