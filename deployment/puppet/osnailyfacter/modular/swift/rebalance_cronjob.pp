notice('MODULAR: swift/rebalance_cronjob.pp')

$storage_hash        = hiera('storage_hash')
$ring_min_part_hours = hiera('swift_ring_min_part_hours', 1)

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $master_swift_proxy_nodes = filter_nodes(hiera('nodes_hash'),'role','primary-controller')
  $master_swift_proxy_ip    = $master_swift_proxy_nodes[0]['storage_address']

  # setup a cronjob to rebalance and repush rings periodically
  class { 'openstack::swift::rebalance_cronjob':
    ring_rebalance_period => min($ring_min_part_hours * 2, 23),
    master_swift_proxy_ip => $master_swift_proxy_ip,
    primary_proxy         => hiera('primary_controller'),
  }
}
