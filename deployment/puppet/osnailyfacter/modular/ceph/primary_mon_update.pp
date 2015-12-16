notice('MODULAR: ceph/primary_mon_update.pp')

$mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
$primary_mon = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_primary_monitor_node'), 'ceph/public')

$mon_ips = join(values($mon_address_map), ',')
$mon_hosts = join(keys($mon_address_map), ',')

$primary_mon_hostname = join(keys($primary_mon))
$primary_mon_ip = join(values($primary_mon))

$storage_hash                     = hiera('storage', {})
if ($storage_hash['volumes_ceph'] or
  $storage_hash['images_ceph'] or
  $storage_hash['objects_ceph'] or
  $storage_hash['ephemeral_ceph']
) {
  $use_ceph = true
} else {
  $use_ceph = false
}

if $use_ceph {
  if $primary_mon_hostname == $::hostname {
    exec {'Wait for Ceph quorum':
      path      => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
      # this can be replaced with "ceph mon status mon.$::host" for Dumpling
      command   => 'ps ax|grep -vq ceph-create-keys',
      returns   => 0,
      tries     => 60,  # This is necessary to prevent a race: mon must establish
      # a quorum before it can generate keys, observed this takes upto 15 seconds
      # Keys must exist prior to other commands running
      try_sleep => 1,
    }

    ceph_config {
      'global/mon_host':            value => $mon_ips;
      'global/mon_initial_members': value => $mon_hosts;
    }

    exec {'reload Ceph for HA':
      path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
      command => 'service ceph reload',
    }

    Exec['Wait for Ceph quorum'] -> Ceph_config<||> ~> Exec['reload Ceph for HA']
  }
}

