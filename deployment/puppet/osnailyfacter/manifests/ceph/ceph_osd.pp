class osnailyfacter::ceph::ceph_osd {

  notice('MODULAR: ceph-osd.pp')

  $storage_hash              = hiera('storage', {})
  $admin_key                 = $storage_hash['admin_key']
  $bootstrap_osd_key         = $storage_hash['bootstrap_osd_key']
  $fsid                      = $storage_hash['fsid']
  $osd_pool_default_size     = $storage_hash['osd_pool_size']
  $osd_pool_default_pg_num   = $storage_hash['pg_num']
  $osd_pool_default_pgp_num  = $storage_hash['pg_num']
  $osd_pool_default_min_size = pick($storage_hash['osd_pool_default_min_size'], '1')
  $osd_journal_size          = pick($storage_hash['osd_journal_size'],  '2048')
  $debug                     = pick($storage_hash['debug'], hiera('debug', true))
  $ceph_tuning_settings      = hiera('ceph_tuning_settings', {})
  $ssl_hash                  = hiera_hash('use_ssl', {})

  $filestore_xattr_use_omap           = pick($storage_hash['filestore_xattr_use_omap'], true)
  $osd_recovery_max_active            = pick($storage_hash['osd_recovery_max_active'], '1')
  $osd_max_backfills                  = pick($storage_hash['osd_max_backfills'], '1')
  $rbd_cache_writethrough_until_flush = pick($storage_hash['rbd_cache_writethrough_until_flush'], true)
  $rbd_cache                          = pick($storage_hash['rbd_cache'], true)
  $log_to_syslog                      = hiera('use_syslog', true)
  $log_to_syslog_level                = pick($storage_hash['ceph_syslog_level'], 'info')
  $log_to_syslog_facility             = pick($storage_hash['ceph_syslog_facility'], 'LOG_LOCAL0')

  prepare_network_config(hiera_hash('network_scheme'))
  $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
  $ceph_public_network  = get_network_role_property('ceph/public', 'network')

  $mon_address_map     = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $mon_host            = join(sorted_hosts($mon_address_map, 'ip'), ',')
  $mon_initial_members = join(sorted_hosts($mon_address_map, 'host'), ',')

  if empty($admin_key) {
    fail('Please provide admin_key')
  }
  if empty($bootstrap_osd_key) {
    fail('Please provide bootstrap_osd_key')
  }
  if empty($fsid) {
    fail('Please provide fsid')
  }

  class { '::ceph':
    fsid                      => $fsid,
    mon_initial_members       => $mon_initial_members,
    mon_host                  => $mon_host,
    cluster_network           => $ceph_cluster_network,
    public_network            => $ceph_public_network,
    osd_pool_default_size     => $osd_pool_default_size,
    osd_pool_default_pg_num   => $osd_pool_default_pg_num,
    osd_pool_default_pgp_num  => $osd_pool_default_pgp_num,
    osd_pool_default_min_size => $osd_pool_default_min_size,
    osd_journal_size          => $osd_journal_size,
    osd_max_backfills         => $osd_max_backfills,
    osd_recovery_max_active   => $osd_recovery_max_active,
    osd_op_threads            => $ceph_tuning_settings['osd_op_threads'],
    # TODO(mmalchuk) remove set_osd_params when deprecated
    set_osd_params            => true,
  }

  ceph_config {
    'global/filestore_xattr_use_omap'           : value => $filestore_xattr_use_omap;
    'client/rbd_cache_writethrough_until_flush' : value => $rbd_cache_writethrough_until_flush;
    'client/rbd_cache'                          : value => $rbd_cache;
    'global/log_to_syslog'                      : value => $log_to_syslog;
    'global/log_to_syslog_level'                : value => $log_to_syslog_level;
    'global/log_to_syslog_facility'             : value => $log_to_syslog_facility;
  }

  Ceph::Key {
    inject => false,
  }

  ceph::key { 'client.admin':
    secret  => $admin_key,
    cap_mon => 'allow *',
    cap_osd => 'allow *',
    cap_mds => 'allow',
  }

  ceph::key {'client.bootstrap-osd':
    keyring_path => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
    secret       => $bootstrap_osd_key,
  }

  $osd_devices_hash = osd_devices_hash($::osd_devices_list)

  class { '::ceph::osds':
    args => $osd_devices_hash,
  }

  if $ceph_tuning_settings != {} {
    ceph_config {
      'global/debug_default'                    : value => $debug;
      'global/max_open_files'                   : value => $ceph_tuning_settings['max_open_files'];
      'osd/osd_mkfs_type'                       : value => $ceph_tuning_settings['osd_mkfs_type'];
      'osd/osd_mount_options_xfs'               : value => $ceph_tuning_settings['osd_mount_options_xfs'];
      'osd/filestore_queue_max_ops'             : value => $ceph_tuning_settings['filestore_queue_max_ops'];
      'osd/filestore_queue_committing_max_ops'  : value => $ceph_tuning_settings['filestore_queue_committing_max_ops'];
      'osd/journal_max_write_entries'           : value => $ceph_tuning_settings['journal_max_write_entries'];
      'osd/journal_queue_max_ops'               : value => $ceph_tuning_settings['journal_queue_max_ops'];
      'osd/objecter_inflight_ops'               : value => $ceph_tuning_settings['objecter_inflight_ops'];
      'osd/filestore_queue_max_bytes'           : value => $ceph_tuning_settings['filestore_queue_max_bytes'];
      'osd/filestore_queue_committing_max_bytes': value => $ceph_tuning_settings['filestore_queue_committing_max_bytes'];
      'osd/journal_max_write_bytes'             : value => $ceph_tuning_settings['journal_max_write_bytes'];
      'osd/journal_queue_max_bytes'             : value => $ceph_tuning_settings['journal_queue_max_bytes'];
      'osd/ms_dispatch_throttle_bytes'          : value => $ceph_tuning_settings['ms_dispatch_throttle_bytes'];
      'osd/objecter_infilght_op_bytes'          : value => $ceph_tuning_settings['objecter_infilght_op_bytes'];
      'osd/filestore_max_sync_interval'         : value => $ceph_tuning_settings['filestore_max_sync_interval'];
    }
  }
}
