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

  case $::osfamily {
    'RedHat': {
      $service_nova_compute = 'openstack-nova-compute'
    }
    'Debian': {
      $service_nova_compute = 'nova-compute'
    }
  }

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

    service { $service_nova_compute: }

    ceph::pool { $compute_pool:
      pg_num  => $compute_pool_pg_num,
      pgp_num => $compute_pool_pgp_num,
    }

    ceph::key { "client.${compute_user}":
      secret  => $secret,
      cap_mon => 'allow r',
      cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}, allow rwx pool=${compute_pool}",
      inject  => true,
    }

    include ::osnailyfacter::ceph_nova_compute

    if ($storage_hash['ephemeral_ceph']) {

      Class['ceph'] ->

      nova_config {
        'libvirt/images_type':      value => $libvirt_images_type;
        'libvirt/inject_key':       value => false;
        'libvirt/inject_partition': value => '-2';
        'libvirt/images_rbd_pool':  value => $compute_pool;
      } ~>

      Service[$service_nova_compute]
    }

    Class['ceph'] ->
    Ceph::Pool[$compute_pool] ->
    Class['osnailyfacter::ceph_nova_compute'] ~>
    Service[$service_nova_compute]

    Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
      cwd  => '/root',
    }
  }
}

