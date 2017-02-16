class openstack_tasks::swift::rebalance_cronjob {

  notice('MODULAR: swift/rebalance_cronjob.pp')

  $network_metadata = hiera_hash('network_metadata')

  $storage_hash        = hiera('storage')
  $swift_master_role   = hiera('swift_master_role', 'primary-controller')
  $ring_min_part_hours = hiera('swift_ring_min_part_hours', 1)

  # Use Swift if it isn't replaced by Ceph for BOTH images and objects
  if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) {
    $master_swift_replication_nodes      = get_nodes_hash_by_roles($network_metadata, [$swift_master_role])
    $master_swift_replication_nodes_list = values($master_swift_replication_nodes)
    $master_swift_replication_ip         = $master_swift_replication_nodes_list[0]['network_roles']['swift/replication']

    # setup a cronjob to rebalance and repush rings periodically
    class { 'openstack_tasks::swift::parts::rebalance_cronjob':
      ring_rebalance_period       => min($ring_min_part_hours * 2, 23),
      master_swift_replication_ip => $master_swift_replication_ip,
      primary_proxy               => hiera('is_primary_swift_proxy'),
    }
  }

}
