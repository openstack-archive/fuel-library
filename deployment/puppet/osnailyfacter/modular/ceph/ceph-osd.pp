# TODO(bogdando) add monit ceph-osd services monitoring, if required
notice('MODULAR: ceph-osd.pp')

firewall { '011 ceph-osd allow':
  chain  => 'INPUT',
  dport  => '6800-7100',
  proto  => 'tcp',
  action => accept,
}

Ceph::Key {
  inject => false,
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

ceph::key { 'client.admin':
  secret  => hiera('admin_key'),
  cap_mon => 'allow *',
  cap_osd => 'allow *',
  cap_mds => 'allow',
}

$storage_hash = hiera('storage', {})
$osd_journal_size = hiera(osd_journal_size, "2048")

$mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')

prepare_network_config(hiera_hash('network_scheme'))
$ceph_cluster_network    = get_network_role_property('ceph/replication', 'network')
$ceph_public_network     = get_network_role_property('ceph/public', 'network')

$osd_devices = split($::osd_devices_list, ' ')

define osd_handler {
  if ':' in $name {
    $data_and_journal = split($name, ':')
    # if size($data_and_journal) != 2 {
    #   fail(???????)
    # }
    $data = $data_and_journal[0]
    $journal = $data_and_journal[1]
  } else {
    $data = $name
    $journal = undef
  }

  ceph::osd {$data:
    journal => $journal,
  }
}

# FUEL ships it's own ceph packages
# class { 'ceph::repo':}

class { 'ceph':
  fsid                     => hiera('fsid'),
  osd_journal_size         => $osd_journal_size,
  osd_pool_default_pg_num  => $storage_hash['pg_num'],
  osd_pool_default_pgp_num => $storage_hash['pg_num'],
  osd_pool_default_size    => $storage_hash['osd_pool_size'],
  mon_initial_members      => values($mon_address_map),
  mon_host                 => keys($mon_address_map),
  cluster_network          => $ceph_cluster_network,
  public_network           => $ceph_public_network,
} ->

ceph::key {'client.bootstrap-osd':
   keyring_path => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
   secret       => hiera('bootstrap_osd_key'),
} ->

osd_handler { $osd_devices: }
