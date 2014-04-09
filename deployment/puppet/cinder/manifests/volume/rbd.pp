# == Class: cinder::volume::rbd
#
# Setup Cinder to use the RBD driver.
#
# === Parameters
#
# [*rbd_pool*]
#   (required) Specifies the pool name for the block device driver.
#
# [*rbd_user*]
#   (required) A required parameter to configure OS init scripts and cephx.
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
class cinder::volume::rbd (
  $rbd_pool,
  $rbd_user,
  $rbd_ceph_conf                    = '/etc/ceph/ceph.conf',
  $rbd_flatten_volume_from_snapshot = false,
  $rbd_secret_uuid                  = false,
  $volume_tmp_dir                   = false,
  $rbd_max_clone_depth              = '5',
  # DEPRECATED PARAMETERS
  $glance_api_version               = undef,
) {

  cinder::backend::rbd { 'DEFAULT':
    rbd_pool                         => $rbd_pool,
    rbd_user                         => $rbd_user,
    rbd_ceph_conf                    => $rbd_ceph_conf,
    rbd_flatten_volume_from_snapshot => $rbd_flatten_volume_from_snapshot,
    rbd_secret_uuid                  => $rbd_secret_uuid,
    volume_tmp_dir                   => $volume_tmp_dir,
    rbd_max_clone_depth              => $rbd_max_clone_depth,
    glance_api_version               => $glance_api_version,
  }
}
