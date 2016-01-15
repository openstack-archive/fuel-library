notice('MODULAR: ceph/ceph_pools')

$storage_hash             = hiera('storage', {})
$secret                   = hiera('mon_key')
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

package {'ceph':}

Exec { path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  cwd     => '/root',
}

$per_pool_pg_nums = $storage_hash['per_pool_pg_nums']

# DO NOT SPLIT ceph auth command lines! See http://tracker.ceph.com/issues/3279
ceph::pool { $glance_pool:
  pg_num  => pick($per_pool_pg_nums[$glance_pool], '256'),
  pgp_num => pick($per_pool_pg_nums[$glance_pool], '256'),

} 

ceph::key { "client.${glance_user}":
  secret  => $secret,
  user    => 'glance',
  group   => 'glance',
  cap_mon => 'allow r',
  cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${glance_pool}",
  inject  => true,
}

ceph::pool { $cinder_pool:
  pg_num  => pick($per_pool_pg_nums[$glance_pool], '256'),
  pgp_num => pick($per_pool_pg_nums[$glance_pool], '256'),
}

ceph::key { "client.${cinder_user}":
  secret  => $secret,
  user    => 'cinder',
  group   => 'cinder',
  cap_mon => 'allow r',
  cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}",
  inject  => true,
}

ceph::pool { $cinder_backup_pool:
  pg_num  => pick($per_pool_pg_nums[$glance_pool], '256'),
  pgp_num => pick($per_pool_pg_nums[$glance_pool], '256'),
}

ceph::key { "client.${cinder_backup_user}":
  secret  => $secret,
  user    => 'cinder',
  group   => 'cinder',
  cap_mon => 'allow r',
  cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_backup_pool}, allow rwx pool=${cinder_pool}",
  inject  => true,
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

