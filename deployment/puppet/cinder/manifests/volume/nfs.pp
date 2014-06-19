#
class cinder::volume::nfs (
  $nfs_servers = [],
  $nfs_mount_options = undef,
  $nfs_disk_util = undef,
  $nfs_sparsed_volumes = undef,
  $nfs_mount_point_base = undef,
  $nfs_shares_config = '/etc/cinder/shares.conf',
  $nfs_used_ratio = '0.95',
  $nfs_oversub_ratio = '1.0',
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
  }
}
