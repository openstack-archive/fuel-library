# configures the Ceph RBD backend for Cinder
class cinder::volume::ceph (
  $volume_driver      = $::ceph::volume_driver,
  $glance_api_version = $::ceph::glance_api_version,
  $rbd_pool           = $::ceph::cinder_pool,
  $rbd_user           = $::ceph::cinder_user,
  $rbd_secret_uuid    = $::ceph::rbd_secret_uuid,
) {

  require ::ceph

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
         cwd  => '/root',
  }

  Cinder_config<||> ~> Service['cinder-volume']
  File_line<||> ~> Service['cinder-volume']
  # TODO: this needs to be re-worked to follow https://wiki.openstack.org/wiki/Cinder-multi-backend
  cinder_config {
    'DEFAULT/volume_driver':      value => $volume_driver;
    'DEFAULT/glance_api_version': value => $glance_api_version;
    'DEFAULT/rbd_pool':           value => $rbd_pool;
    'DEFAULT/rbd_user':           value => $rbd_user;
    'DEFAULT/rbd_secret_uuid':    value => $rbd_secret_uuid;
  }

  # TODO: convert to cinder params
  file {$::ceph::params::service_cinder_volume_opts:
    ensure => 'present',
  } -> file_line {'cinder-volume.conf':
    path => $::ceph::params::service_cinder_volume_opts,
    line => "export CEPH_ARGS='--id ${rbd_pool}'",
  }
}
