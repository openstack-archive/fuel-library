class osnailyfacter::ceph::ceph_pools {

  notice('MODULAR: ceph/ceph_pools')

  $storage_hash       = hiera('storage', {})
  $fsid               = pick($storage_hash['fsid'], '066F558C-6789-4A93-AAF1-5AF1BA01A3AD')
  $mon_key            = pick($storage_hash['mon_key'], 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw==')
  $cinder_user        = 'volumes'
  $cinder_pool        = 'volumes'
  $cinder_backup_user = 'backups'
  $cinder_backup_pool = 'backups'
  $glance_user        = 'images'
  $glance_pool        = 'images'


  class {'ceph':
    fsid => $fsid
  }

  $per_pool_pg_nums = $storage_hash['per_pool_pg_nums']

# DO NOT SPLIT ceph auth command lines! See http://tracker.ceph.com/issues/3279
  ceph::pool { $glance_pool:
    pg_num  => pick($per_pool_pg_nums[$glance_pool], '256'),
    pgp_num => pick($per_pool_pg_nums[$glance_pool], '256'),
  }

  ceph::key { "client.${glance_user}":
    secret  => $mon_key,
    user    => 'glance',
    group   => 'glance',
    cap_mon => 'allow r',
    cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${glance_pool}",
    inject  => true,
  }

  ceph::pool { $cinder_pool:
    pg_num  => pick($per_pool_pg_nums[$cinder_pool], '256'),
    pgp_num => pick($per_pool_pg_nums[$cinder_pool], '256'),
  }

  ceph::key { "client.${cinder_user}":
    secret  => $mon_key,
    user    => 'cinder',
    group   => 'cinder',
    cap_mon => 'allow r',
    cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}",
    inject  => true,
  }

  ceph::pool { $cinder_backup_pool:
    pg_num  => pick($per_pool_pg_nums[$cinder_backup_pool], '256'),
    pgp_num => pick($per_pool_pg_nums[$cinder_backup_pool], '256'),
  }

  ceph::key { "client.${cinder_backup_user}":
    secret  => $mon_key,
    user    => 'cinder',
    group   => 'cinder',
    cap_mon => 'allow r',
    cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_backup_pool}, allow rwx pool=${cinder_pool}",
    inject  => true,
  }

  if ($storage_hash['volumes_ceph']) {
    include ::cinder::params
    service { 'cinder-volume':
      ensure     => 'running',
      name       => $::cinder::params::volume_service,
      hasstatus  => true,
      hasrestart => true,
    }

    Ceph::Pool[$cinder_pool] ~> Service['cinder-volume']

    service { 'cinder-backup':
      ensure     => 'running',
      name       => $::cinder::params::backup_service,
      hasstatus  => true,
      hasrestart => true,
    }

    Ceph::Pool[$cinder_backup_pool] ~> Service['cinder-backup']
  }

  if ($storage_hash['images_ceph']) {
    include ::glance::params
    service { 'glance-api':
      ensure     => 'running',
      name       => $::glance::params::api_service_name,
      hasstatus  => true,
      hasrestart => true,
    }

    Ceph::Pool[$glance_pool] ~> Service['glance-api']
  }
}
