class osnailyfacter::ceph::ceph_compute {

  notice('MODULAR: ceph/ceph_compute.pp')

  $storage_hash         = hiera('storage', {})
  $admin_key            = $storage_hash['admin_key']
  $mon_key              = $storage_hash['mon_key']
  $fsid                 = $storage_hash['fsid']
  $cinder_pool          = 'volumes'
  $glance_pool          = 'images'
  $compute_user         = 'compute'
  $compute_pool         = 'compute'
  $secret               = $mon_key
  $per_pool_pg_nums     = $storage_hash['per_pool_pg_nums']
  $compute_pool_pg_num  = pick($per_pool_pg_nums[$compute_pool], '1024')
  $compute_pool_pgp_num = pick($per_pool_pg_nums[$compute_pool], '1024')

  prepare_network_config(hiera_hash('network_scheme', {}))
  $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
  $ceph_public_network  = get_network_role_property('ceph/public', 'network')

  $mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $mon_ips         = join(sorted_hosts($mon_address_map, 'ip'), ',')
  $mon_hosts       = join(sorted_hosts($mon_address_map, 'host'), ',')

  if !($storage_hash['ephemeral_ceph']) {
    $libvirt_images_type = 'default'
  } else {
    $libvirt_images_type = 'rbd'
  }

  if ($storage_hash['volumes_ceph'] or
    $storage_hash['images_ceph'] or
    $storage_hash['objects_ceph'] or
    $storage_hash['ephemeral_ceph']
  ) {

    if empty($admin_key) {
      fail('Please provide admin_key')
    }
    if empty($mon_key) {
      fail('Please provide mon_key')
    }
    if empty($fsid) {
      fail('Please provide fsid')
    }

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

    ceph::key { 'client.admin':
      secret  => $admin_key,
      cap_mon => 'allow *',
      cap_osd => 'allow *',
      cap_mds => 'allow',
    }

    ceph::key { "client.${compute_user}":
      user    => 'nova',
      group   => 'nova',
      secret  => $secret,
      cap_mon => 'allow r',
      cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rwx pool=${glance_pool}, allow rwx pool=${compute_pool}",
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
