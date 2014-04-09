#
# == Class: cinder::volume::glusterfs
#
# Configures Cinder to use GlusterFS as a volume driver
#
# === Parameters
#
# [*glusterfs_shares*]
#   (required) An array of GlusterFS volume locations.
#   Must be an array even if there is only one volume.
#
# [*glusterfs_disk_util*]
#   Removed in Icehouse.
#
# [*glusterfs_sparsed_volumes*]
#   (optional) Whether or not to use sparse (thin) volumes.
#   Defaults to undef which uses the driver's default of "true".
#
# [*glusterfs_mount_point_base*]
#   (optional) Where to mount the Gluster volumes.
#   Defaults to undef which uses the driver's default of "$state_path/mnt".
#
# [*glusterfs_shares_config*]
#   (optional) The config file to store the given $glusterfs_shares.
#   Defaults to '/etc/cinder/shares.conf'
#
# === Examples
#
# class { 'cinder::volume::glusterfs':
#   glusterfs_shares = ['192.168.1.1:/volumes'],
# }
#
class cinder::volume::glusterfs (
  $glusterfs_shares,
  $glusterfs_disk_util        = false,
  $glusterfs_sparsed_volumes  = undef,
  $glusterfs_mount_point_base = undef,
  $glusterfs_shares_config    = '/etc/cinder/shares.conf'
) {

  cinder::backend::glusterfs { 'DEFAULT':
    glusterfs_shares           => $glusterfs_shares,
    glusterfs_disk_util        => $glusterfs_disk_util,
    glusterfs_sparsed_volumes  => $glusterfs_sparsed_volumes,
    glusterfs_mount_point_base => $glusterfs_mount_point_base,
    glusterfs_shares_config    => $glusterfs_shares_config,
  }
}
