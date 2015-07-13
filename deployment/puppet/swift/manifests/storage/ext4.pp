# follow the instructions for creating a loopback device
# for storage from: http://swift.openstack.org/development_saio.html
#
# this define needs to be sent a refresh signal to do anything
#
# === Parameters:
#
# [*device*]
#   (mandatory) An array of devices (prefixed or not by /dev)
#
# [*mnt_base_dir*]
#   (optional) The directory where the flat files that store the file system
#   to be loop back mounted are actually mounted at.
#   Defaults to '/srv/node', base directory where disks are mounted to
#
# [*byte_size*]
#   (optional) The byte size that dd uses when it creates the file system.
#   Defaults to '1024', block size for the disk.  For very large partitions, this should be larger
#   It is recommened to use 1024 to ensure that the metadata can fit in a single inode.
#
# [*loopback*]
#   (optional) Define if the device must be mounted as a loopback or not
#   Defaults to false.
#
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
    device       => $device,
    mnt_base_dir => $mnt_base_dir,
    subscribe    => Exec["mkfs-${name}"],
    loopback     => $loopback,
    fstype       => 'ext4',
  }

}
