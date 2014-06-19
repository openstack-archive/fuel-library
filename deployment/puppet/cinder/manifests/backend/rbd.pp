# == define: cinder::backend::rbd
#
# Setup Cinder to use the RBD driver.
# Compatible for multiple backends
#
# === Parameters
#
# [*rbd_pool*]
#   (required) Specifies the pool name for the block device driver.
#
# [*rbd_user*]
#   (required) A required parameter to configure OS init scripts and cephx.
#
# [*volume_backend_name*]
#   (optional) Allows for the volume_backend_name to be separate of $name.
#   Defaults to: $name
#
# [*rbd_ceph_conf*]
#   (optional) Path to the ceph configuration file to use
#   Defaults to '/etc/ceph/ceph.conf'
#
# [*rbd_flatten_volume_from_snapshot*]
#   (optional) Enable flatten volumes created from snapshots.
#   Defaults to false
#
# [*rbd_secret_uuid*]
#   (optional) A required parameter to use cephx.
#   Defaults to false
#
# [*volume_tmp_dir*]
#   (optional) Location to store temporary image files if the volume
#   driver does not write them directly to the volume
#   Defaults to false
#
# [*rbd_max_clone_depth*]
#   (optional) Maximum number of nested clones that can be taken of a
#   volume before enforcing a flatten prior to next clone.
#   A value of zero disables cloning
#   Defaults to '5'
#
# [*glance_api_version*]
#   (optional) DEPRECATED: Use cinder::glance Class instead.
#   Glance API version. (Defaults to '2')
#   Setting this parameter cause a duplicate resource declaration
#   with cinder::glance
#
define cinder::backend::rbd (
  $rbd_pool,
  $rbd_user,
  $volume_backend_name              = $name,
  $rbd_ceph_conf                    = '/etc/ceph/ceph.conf',
  $rbd_flatten_volume_from_snapshot = false,
  $rbd_secret_uuid                  = false,
  $volume_tmp_dir                   = false,
  $rbd_max_clone_depth              = '5',
  # DEPRECATED PARAMETERS
  $glance_api_version               = undef,
) {

  include cinder::params

  if $glance_api_version {
    warning('The glance_api_version parameter is deprecated, use glance_api_version of cinder::glance class instead.')
  }

  cinder_config {
    "${name}/volume_backend_name":              value => $volume_backend_name;
    "${name}/volume_driver":                    value => 'cinder.volume.drivers.rbd.RBDDriver';
    "${name}/rbd_ceph_conf":                    value => $rbd_ceph_conf;
    "${name}/rbd_user":                         value => $rbd_user;
    "${name}/rbd_pool":                         value => $rbd_pool;
    "${name}/rbd_max_clone_depth":              value => $rbd_max_clone_depth;
    "${name}/rbd_flatten_volume_from_snapshot": value => $rbd_flatten_volume_from_snapshot;
  }

  if $rbd_secret_uuid {
    cinder_config {"${name}/rbd_secret_uuid": value => $rbd_secret_uuid;}
  } else {
    cinder_config {"${name}/rbd_secret_uuid": ensure => absent;}
  }

  if $volume_tmp_dir {
    cinder_config {"${name}/volume_tmp_dir": value => $volume_tmp_dir;}
  } else {
    cinder_config {"${name}/volume_tmp_dir": ensure => absent;}
  }

  case $::osfamily {
    'Debian': {
      $override_line    = "env CEPH_ARGS=\"--id ${rbd_user}\""
    }
    'RedHat': {
      $override_line    = "export CEPH_ARGS=\"--id ${rbd_user}\""
    }
    default: {
      fail("unsuported osfamily ${::osfamily}, currently Debian and Redhat are the only supported platforms")
    }
  }

  # Creates an empty file if it doesn't yet exist
  ensure_resource('file', $::cinder::params::ceph_init_override, {'ensure' => 'present'})

  ensure_resource('file_line', 'set initscript env', {
    line   => $override_line,
    path   => $::cinder::params::ceph_init_override,
    notify => Service['cinder-volume']
  })

}
