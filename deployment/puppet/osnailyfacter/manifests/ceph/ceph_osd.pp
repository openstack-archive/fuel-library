class osnailyfacter::ceph::ceph_osd {

  # TODO(bogdando) add monit ceph-osd services monitoring, if required
  notice('MODULAR: ceph-osd.pp')

  $storage_hash              = hiera('storage', {})
  $admin_key                 = pick($storage_hash['admin_key'], 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ==')
  $bootstrap_osd_key         = pick($storage_hash['bootstrap_osd_key'], 'AQABsWZSgEDmJhAAkAGSOOAJwrMHrM5Pz5On1A==')
  $fsid                      = pick($storage_hash['fsid'], '066F558C-6789-4A93-AAF1-5AF1BA01A3AD')
  $osd_pool_default_size     = $storage_hash['osd_pool_size']
  $osd_pool_default_pg_num   = $storage_hash['pg_num']
  $osd_pool_default_pgp_num  = $storage_hash['pg_num']
  $osd_pool_default_min_size = pick($storage_hash['osd_pool_default_min_size'], '1')
  $osd_journal_size          = pick($storage_hash['osd_journal_size'],  '2048')
  $debug                     = pick($storage_hash['debug'], hiera('debug', true))
  $ceph_tuning_settings      = hiera('ceph_tuning_settings', {})
  $ssl_hash                  = hiera_hash('use_ssl', {})

  prepare_network_config(hiera_hash('network_scheme'))
  $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
  $ceph_public_network  = get_network_role_property('ceph/public', 'network')

  $mon_address_map     = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $mon_host            = join(values($mon_address_map), ',')
  $mon_initial_members = join(keys($mon_address_map), ',')

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
  }

  ceph_config {
    'global/osd_mkfs_type'                      : value => 'xfs';
    'global/filestore_xattr_use_omap'           : value => true;
    'global/osd_recovery_max_active'            : value => '1';
    'global/osd_max_backfills'                  : value => '1';
    'client/rbd_cache_writethrough_until_flush' : value => true;
    'client/rbd_cache'                          : value => true;
    'global/log_to_syslog'                      : value => true;
    'global/log_to_syslog_level'                : value => 'info';
    'global/log_to_syslog_facility'             : value => 'LOG_LOCAL0';
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
  } ->

  service {'ceph-osd-all-starter':
    ensure   => running,
    provider => upstart,
  }

  if $ceph_tuning_settings != {} {
    ceph_config {
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
  }
}

