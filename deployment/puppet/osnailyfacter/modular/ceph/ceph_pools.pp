notice('MODULAR: ceph/ceph_pools')

$storage_hash     = hiera('storage', {})
$per_pool_pg_nums = $storage_hash['per_pool_pg_nums']


Exec { path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  cwd     => '/root',
}

if ($storage_hash['volumes_ceph']) {
  include ::cinder::params

  # Cinder settings
  $cinder_user = 'volumes'
  $cinder_pool = 'volumes'

  # DO NOT SPLIT ceph auth command lines! See http://tracker.ceph.com/issues/3279
  ceph::key {"client.${cinder_user}":
    cap_mon => "allow r",
    cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}"
    user    => "cinder"
  } -> 
  ceph::pool {$cinder_pool:
    pg_num  => $per_pool_pg_nums[$cinder_pool],
    pgp_num => $per_pool_pg_nums[$cinder_pool],
  } ~>
  service { $::cinder::params::volume_service:
    ensure     => 'running',
    hasstatus  => true,
    hasrestart => true,
  }  

  # Cinder Backup settings
  $cinder_backup_user = 'backups'
  $cinder_backup_pool = 'backups'

  ceph::key {"client.${cinder_backup_user}":
    cap_mon => "allow r",
    cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_backup_pool}, allow rx pool=${cinder_pool}"
    user    => "cinder"
  } ->
  ceph::pool {$cinder_backup_pool:
    pg_num  => $per_pool_pg_nums[$cinder_backup_pool],
    pgp_num => $per_pool_pg_nums[$cinder_backup_pool],
  } ~>
  service { $::cinder::params::backup_service:
    ensure     => 'running',
    hasstatus  => true,
    hasrestart => true,
  }
}

if ($storage_hash['images_ceph']) {
  include ::glance::params

  # Glance settings
  $glance_user = 'images'
  $glance_pool = 'images'

  ceph::key {"client.${glance_user}":
    cap_mon => "allow r",
    cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${glance_pool}"
    user => "glance"
  } ->
  ceph::pool {$glance_pool:
    pg_num  => $per_pool_pg_nums[$glance_pool],
    pgp_num => $per_pool_pg_nums[$glance_pool],
  } ~>
  service { $::glance::params::api_service_name:
    ensure     => 'running',
    hasstatus  => true,
    hasrestart => true,
  }
}

