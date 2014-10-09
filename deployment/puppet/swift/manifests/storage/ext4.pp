# follow the instructions for creating a loopback device
# for storage from: http://swift.openstack.org/development_saio.html
#
#
#
# this define needs to be sent a refresh signal to do anything
#
#
# [*title*]
#
# [*byte_size*] Byte size to use for every inode in the created filesystem.
#  It is recommened to use 1024 to ensure that the metadata can fit in a single inode.
define swift::storage::ext4(
  $device,
  $byte_size    = '1024',
  $mnt_base_dir = '/srv/node',
  $loopback     = false
) {

  # does this have to be refreshonly?
  # how can I know if this drive has been formatted?
  exec { "mkfs-${name}":
    command     => "mkfs.ext4 -I ${byte_size} -F ${device}",
    path        => ['/sbin/'],
    refreshonly => true,
  }

  swift::storage::mount { $name:
    device         => $device,
    mnt_base_dir   => $mnt_base_dir,
    subscribe      => Exec["mkfs-${name}"],
    loopback       => $loopback,
    fstype         => 'ext4',
  }

}
