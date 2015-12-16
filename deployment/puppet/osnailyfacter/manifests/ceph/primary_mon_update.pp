class osnailyfacter::ceph::primary_mon_update {

  notice('MODULAR: ceph/primary_mon_update.pp')

  $mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $mon_ips         = join(values($mon_address_map), ',')
  $mon_hosts       = join(keys($mon_address_map), ',')

  $storage_hash = hiera('storage', {})

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
    exec {'Wait for Ceph quorum':
      path        => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
      command     => "ceph mon stat | grep -q 'quorum.*${node_hostname}'",
      tries       => 12,  # This is necessary to prevent a race: mon must establish
      # a quorum before it can generate keys, observed this takes upto 15 seconds
      # Keys must exist prior to other commands running
      try_sleep   => 5,
      refreshonly => true,
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
