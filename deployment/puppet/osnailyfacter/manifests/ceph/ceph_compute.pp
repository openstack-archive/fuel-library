class osnailyfacter::ceph::ceph_compute {

  notice('MODULAR: ceph/ceph_compute.pp')

  $storage_hash         = hiera('storage', {})
  $mon_key              = pick($storage_hash['mon_key'], 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw==')
  $fsid                 = pick($storage_hash['fsid'], '066F558C-6789-4A93-AAF1-5AF1BA01A3AD')
  $cinder_pool          = 'volumes'
  $glance_pool          = 'images'
  $compute_user         = 'compute'
  $compute_pool         = 'compute'
  $libvirt_images_type  = 'rbd'
  $secret               = $mon_key
  $per_pool_pg_nums     = $storage_hash['per_pool_pg_nums']
  $compute_pool_pg_num  = pick($per_pool_pg_nums[$compute_pool], '1024')
  $compute_pool_pgp_num = pick($per_pool_pg_nums[$compute_pool], '1024')

  prepare_network_config(hiera_hash('network_scheme', {}))
  $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
  $ceph_public_network  = get_network_role_property('ceph/public', 'network')

  $mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $mon_ips         = join(values($mon_address_map), ',')
  $mon_hosts       = join(keys($mon_address_map), ',')

  if $storage_hash['ephemeral_ceph'] {
    $use_ceph = true
  } else {
    $use_ceph = false
  }

  if $use_ceph {
    class { '::ceph':
      fsid                => $fsid,
      mon_initial_members => $mon_hosts,
      mon_host            => $mon_ips,
      cluster_network     => $ceph_cluster_network,
      public_network      => $ceph_public_network,
    }

    ceph::pool { $compute_pool:
      pg_num  => $compute_pool_pg_num,
      pgp_num => $compute_pool_pgp_num,
    }

    ceph::key { "client.${compute_user}":
      user    => 'nova',
      group   => 'nova',
      secret  => $secret,
      cap_mon => 'allow r',
      cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}, allow rwx pool=${compute_pool}",
      inject  => true,
    }

    class {'::osnailyfacter::ceph_nova_compute':
      user                => $compute_user,
      compute_pool        => $compute_pool,
      libvirt_images_type => $libvirt_images_type,
    }

    Class['ceph'] ->
    Ceph::Pool[$compute_pool] ->
    Class['osnailyfacter::ceph_nova_compute']
  }
}
