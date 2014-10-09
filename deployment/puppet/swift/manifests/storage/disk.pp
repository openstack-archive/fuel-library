# This Puppet resource is based on the following
# instructions for creating a disk device:
# http://swift.openstack.org/development_saio.html
#
# ==Add a raw disk to a swift storage node==
#
# It will do two steps to create a disk device:
#   - creates a disk table, use the whole disk instead
#     to make the partition (e.g. use sdb as a whole)
#   - formats the partition to an xfs device and
#     mounts it as a block device at /srv/node/$name
#
# ATTENTION: You should not use the disk that your Operating System
#            is installed on (typically /dev/sda/).
#
# =Parameters=
# $base_dir = '/dev', assumes local disk devices
# $mnt_base_dir = '/srv/node', base directory where disks are mounted to
# $byte_size = '1024', block size for the disk.  For very large partitions, this should be larger
#
# =Example=
#
# Simply add one disk sdb:
#
# swift::storage::disk { "sdb":}
#
# Add more than one disks and overwrite byte_size:
#
# swift::storage::disk {['sdb','sdc','sdd']:
#   byte_size   =>   '2048',
#   }
#
# TODO(yuxcer): maybe we can remove param $base_dir

define swift::storage::disk(
  $base_dir     = '/dev',
  $mnt_base_dir = '/srv/node',
  $byte_size    = '1024',
) {

  if(!defined(File[$mnt_base_dir])) {
    file { $mnt_base_dir:
      ensure => directory,
      owner  => 'swift',
      group  => 'swift',
    }
  }

  exec { "create_partition_label-${name}":
    command     => "parted -s ${base_dir}/${name} mklabel gpt",
    path        => ['/usr/bin/', '/sbin','/bin'],
    onlyif      => ["test -b ${base_dir}/${name}","parted ${base_dir}/${name} print|tail -1|grep 'Error'"],
  }

  swift::storage::xfs { $name:
    device       => "${base_dir}/${name}",
    mnt_base_dir => $mnt_base_dir,
    byte_size    => $byte_size,
    loopback     => false,
    subscribe    => Exec["create_partition_label-${name}"],
  }

}
