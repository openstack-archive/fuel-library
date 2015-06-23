# == Class: cinder::volume::nfs
#
#
# === Parameters
#
# [*nfs_servers*]
#   (Required) Description
#   Defaults to '[]'
#
# [*nfs_mount_options*]
#   (Optional) Mount options passed to the nfs client.
#   Defaults to 'undef'.
#
# [*nfs_disk_util*]
#   (Optional) TODO
#   Defaults to 'undef'.
#
# [*nfs_sparsed_volumes*]
#   (Optional) Create volumes as sparsed files which take no space.
#   If set to False volume is created as regular file.
#   In such case volume creation takes a lot of time.
#   Defaults to 'undef'.
#
# [*nfs_mount_point_base*]
#   (Optional) Base dir containing mount points for nfs shares.
#   Defaults to 'undef'.
#
# [*nfs_shares_config*]
#   (Optional) File with the list of available nfs shares.
#   Defaults to '/etc/cinder/shares.conf'.
#
# [*nfs_used_ratio*]
#   (Optional) Percent of ACTUAL usage of the underlying volume before no new
#   volumes can be allocated to the volume destination.
#   Defaults to '0.95'.
#
# [*nfs_oversub_ratio*]
#   (Optional) This will compare the allocated to available space on the volume
#   destination. If the ratio exceeds this number, the destination will no
#   longer be valid.
#   Defaults to '1.0'.
#
# [*extra_options*]
#   (optional) Hash of extra options to pass to the backend stanza
#   Defaults to: {}
#   Example :
#     { 'nfs_backend/param1' => { 'value' => value1 } }
#
class cinder::volume::nfs (
  $nfs_servers          = [],
  $nfs_mount_options    = undef,
  $nfs_disk_util        = undef,
  $nfs_sparsed_volumes  = undef,
  $nfs_mount_point_base = undef,
  $nfs_shares_config    = '/etc/cinder/shares.conf',
  $nfs_used_ratio       = '0.95',
  $nfs_oversub_ratio    = '1.0',
  $extra_options        = {},
) {

  cinder::backend::nfs { 'DEFAULT':
    nfs_servers          => $nfs_servers,
    nfs_mount_options    => $nfs_mount_options,
    nfs_disk_util        => $nfs_disk_util,
    nfs_sparsed_volumes  => $nfs_sparsed_volumes,
    nfs_mount_point_base => $nfs_mount_point_base,
    nfs_shares_config    => $nfs_shares_config,
    nfs_used_ratio       => $nfs_used_ratio,
    nfs_oversub_ratio    => $nfs_oversub_ratio,
    extra_options        => $extra_options,
  }
}
