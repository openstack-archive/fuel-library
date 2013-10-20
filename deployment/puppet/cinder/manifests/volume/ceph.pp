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
  # TODO: this needs to be re-worked to follow https://wiki.openstack.org/wiki/Cinder-multi-backend
  cinder_config {
    'DEFAULT/volume_driver':      value => $volume_driver;
    'DEFAULT/glance_api_version': value => $glance_api_version;
    'DEFAULT/rbd_pool':           value => $rbd_pool;
    'DEFAULT/rbd_user':           value => $rbd_user;
    'DEFAULT/rbd_secret_uuid':    value => $rbd_secret_uuid;
  }

  # TODO: convert to cinder params
  define cinder::volume::ceph::env (
    $rbd_pool = $::cinder::volume::ceph::rbd_pool,
  ) {

    case $::osfamily {
      'RedHat': {
        file {$::cinder::params::volume_opts_file:
          ensure => present,
        } ->
        file_line {'cinder-volume env':
          path => $::cinder::params::volume_opts_file,
          line => "export CEPH_ARGS='--id ${rbd_pool}'",
        }
      }

      'Debian': {
        Package[$::cinder::params::volume_package] ->
        file_line {'cinder-volume env':
          path => $::cinder::params::volume_opts_file,
          line => "env CEPH_ARGS='--id ${rbd_pool}'",
        }
      }

      default: {}
    }
  }

  cinder::volume::ceph::env {'CEPH_ARGS': } ~> Service['cinder-volume']
}
