class openstack_tasks::swift::rebalance_cronjob {

  notice('MODULAR: swift/rebalance_cronjob.pp')

  $network_metadata = hiera_hash('network_metadata')

  $storage_hash        = hiera('storage')
  $swift_master_role   = hiera('swift_master_role', 'primary-controller')
  $ring_min_part_hours = hiera('swift_ring_min_part_hours', 1)

  # Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
  if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
    $master_swift_replication_nodes      = get_nodes_hash_by_roles($network_metadata, [$swift_master_role])
    $master_swift_replication_nodes_list = values($master_swift_replication_nodes)
    $master_swift_replication_ip         = $master_swift_replication_nodes_list[0]['network_roles']['swift/replication']

    # setup a cronjob to rebalance and repush rings periodically
    class { 'openstack::swift::rebalance_cronjob':
      ring_rebalance_period       => min($ring_min_part_hours * 2, 23),
      master_swift_replication_ip => $master_swift_replication_ip,
      primary_proxy               => hiera('is_primary_swift_proxy'),
    }
  }

  class openstack::swift::rebalance_cronjob(
    $master_swift_replication_ip,
    $primary_proxy         = false,
    $rings                 = ['account', 'object', 'container'],
    $ring_rebalance_period = 23,
  ) {

    # setup a cronjob to rebalance rings periodically on primary
    file { '/usr/local/bin/swift-rings-rebalance.sh':
      ensure  => $primary_proxy ? {
        true    => file,
        default => absent,
      },
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => template('openstack/swift/swift-rings-rebalance.sh.erb'),
    }
    cron { 'swift-rings-rebalance':
      ensure  => $primary_proxy ? {
        true    => present,
        default => absent,
      },
      command => '/usr/local/bin/swift-rings-rebalance.sh &>/dev/null',
      user    => 'swift',
      hour    => "*/$ring_rebalance_period",
      minute  => '15',
    }

    # setup a cronjob to download rings periodically on secondaries
    file { '/usr/local/bin/swift-rings-sync.sh':
      ensure  => $primary_proxy ? {
        true    => absent,
        default => file,
      },
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => template('openstack/swift/swift-rings-sync.sh.erb'),
    }
    cron { 'swift-rings-sync':
      ensure  => $primary_proxy ? {
        true    => absent,
        default => present,
      },
      command => '/usr/local/bin/swift-rings-sync.sh &>/dev/null',
      user    => 'swift',
      hour    => "*/$ring_rebalance_period",
      minute  => '25',
    }
  }

}
