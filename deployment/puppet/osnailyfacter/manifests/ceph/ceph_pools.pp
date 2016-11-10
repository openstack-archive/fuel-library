class osnailyfacter::ceph::ceph_pools {

  notice('MODULAR: ceph/ceph_pools.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $storage_hash             = hiera_hash('storage', {})
  $osd_pool_default_pg_num  = $storage_hash['pg_num']
  $osd_pool_default_pgp_num = $storage_hash['pg_num']
  # Cinder settings
  $cinder_user              = 'volumes'
  $cinder_pool              = 'volumes'
  # Cinder Backup settings
  $cinder_backup_user       = 'backups'
  $cinder_backup_pool       = 'backups'
  # Glance settings
  $glance_user              = 'images'
  $glance_pool              = 'images'

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  Exec { path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    cwd     => '/root',
  }

  $per_pool_pg_nums = $storage_hash['per_pool_pg_nums']

  # DO NOT SPLIT ceph auth command lines! See http://tracker.ceph.com/issues/3279
  ceph::pool {$glance_pool:
    user          => $glance_user,
    acl           => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${glance_pool}'",
    keyring_owner => 'glance',
    pg_num        => pick($per_pool_pg_nums[$glance_pool], '256'),
    pgp_num       => pick($per_pool_pg_nums[$glance_pool], '256'),
  }

  ceph::pool {$cinder_pool:
    user          => $cinder_user,
    acl           => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}'",
    keyring_owner => 'cinder',
    pg_num        => pick($per_pool_pg_nums[$cinder_pool], '2048'),
    pgp_num       => pick($per_pool_pg_nums[$cinder_pool], '2048'),
  }

  ceph::pool {$cinder_backup_pool:
    user          => $cinder_backup_user,
    acl           => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${cinder_backup_pool}, allow rwx pool=${cinder_pool}'",
    keyring_owner => 'cinder',
    pg_num        => pick($per_pool_pg_nums[$cinder_backup_pool], '512'),
    pgp_num       => pick($per_pool_pg_nums[$cinder_backup_pool], '512'),
  }

  Ceph::Pool[$glance_pool] -> Ceph::Pool[$cinder_pool] -> Ceph::Pool[$cinder_backup_pool]

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
