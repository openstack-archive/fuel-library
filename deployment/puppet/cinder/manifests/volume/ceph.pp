# configures the Ceph RBD backend for Cinder
class cinder::volume::ceph (
  $volume_driver      = $::ceph::volume_driver,
  $glance_api_version = $::ceph::glance_api_version,
  $rbd_pool           = $::ceph::cinder_pool,
  $rbd_user           = $::ceph::cinder_user,
  $rbd_secret_uuid    = $::ceph::rbd_secret_uuid,
) {

  include cinder::params

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

#  # TODO: convert to cinder params
#  file {$::ceph::params::service_cinder_volume_opts:
#    ensure => 'present',
#  } -> file_line {'cinder-volume.conf':
#    path => $::ceph::params::service_cinder_volume_opts,
#    line => "export CEPH_ARGS='--id ${rbd_pool}'",
#  }

  case $::osfamily {
    'RedHat': {
      $volume_opts = "export CEPH_ARGS='--id ${rbd_pool}'"
    }
    'Debian': {
      $volume_opts = "env CEPH_ARGS='--id ${rbd_pool}'"
    }
    default: {
      $volume_opts=undef
    }
  }

  file {'cinder-volume init file':
    path    => $::cinder::params::volume_opts_file,
    ensure  => present,
  }

  if ($::cinder::params::volume_package) {
      $volume_package = $::cinder::params::volume_package
    } else {
      $volume_package = $::cinder::params::package_name
  }

  Package[$volume_package] -> File_line['cinder-volume init config']

  file_line {'cinder-volume init config':
    path    => $::cinder::params::volume_opts_file,
    line    => "${volume_opts}",
  } ~> Service['cinder-volume']

}
