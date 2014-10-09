# [*title*]
#
# [*byte_size*] Byte size to use for every inode in the created filesystem.
#  It is recommened to use 1024 to ensure that the metadata can fit in a single inode.
#
#
# Sample usage:
#
# swift::storage::xfs {
#   ['sdb', 'sdc', 'sde', 'sdf', 'sdg', 'sdh', 'sdi', 'sdj', 'sdk']:
#     mnt_base_dir => '/srv/node',
#     require      => Class['swift'];
# }
#
# Creates /srv/node if dir does not exist, formats sdbX with XFS unless
# it already has an XFS FS, and mounts de FS in /srv/node/sdX
#
define swift::storage::xfs(
  $device       = '',
  $byte_size    = '1024',
  $mnt_base_dir = '/srv/node',
  $loopback     = false
) {

  include swift::xfs

  if $device == '' {
    $target_device = "/dev/${name}"
  } else {
    $target_device = $device
  }

  if(!defined(File[$mnt_base_dir])) {
    file { $mnt_base_dir:
      ensure => directory,
      owner  => 'swift',
      group  => 'swift',
    }
  }

  # We use xfs_admin -l to print FS label
  # If it's not a valid XFS FS, command will return 1
  # so we format it. If device has a valid XFS FS, command returns 0
  # So we do NOT touch it.
  exec { "mkfs-${name}":
    command => "mkfs.xfs -f -i size=${byte_size} ${target_device}",
    path    => ['/sbin/', '/usr/sbin/'],
    require => Package['xfsprogs'],
    unless  => "xfs_admin -l ${target_device}",
  }

  swift::storage::mount { $name:
    device         => $target_device,
    mnt_base_dir   => $mnt_base_dir,
    subscribe      => Exec["mkfs-${name}"],
    loopback       => $loopback,
  }

}
