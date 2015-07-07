# follow the instructions for creating a loopback device
# for storage from: http://swift.openstack.org/development_saio.html
#
#
# creates a managed loopback interface
#   - creates a file
#   - formats the file to be an xfs device and mounts it as a loopback device at /srv/node/$name
#   - sets up each mount point as a swift endpoint
# === Parameters:
#
# [*base_dir*]
#   (optional) The directory where the flat files will be stored that house
#   the file system to be loop back mounted.
#   Defaults to '/dev', assumes local disk devices
#
# [*mnt_base_dir*]
#   (optional) The directory where the flat files that store the file system
#   to be loop back mounted are actually mounted at.
#   Defaults to '/srv/node', base directory where disks are mounted to
#
# [*byte_size*]
#   (optional) The byte size that dd uses when it creates the file system.
#   Defaults to '1024', block size for the disk.  For very large partitions, this should be larger
#
# [*seek*]
#   (optional) The size of the file system that will be created.
#    Defaults to 25000.
#
# [*fstype*]
#   (optional) The filesystem type.
#   Defaults to 'xfs'.
#
define swift::storage::loopback(
  $base_dir     = '/srv/loopback-device',
  $mnt_base_dir = '/srv/node',
  $byte_size    = '1024',
  $seek         = '25000',
  $fstype       = 'xfs'
) {

  if(!defined(File[$base_dir])) {
    file { $base_dir:
      ensure => directory,
    }
  }

  if(!defined(File[$mnt_base_dir])) {
    file { $mnt_base_dir:
      ensure => directory,
      owner  => 'swift',
      group  => 'swift',
    }
  }

  exec { "create_partition-${name}":
    command => "dd if=/dev/zero of=${base_dir}/${name} bs=${byte_size} count=0 seek=${seek}",
    path    => ['/usr/bin/', '/bin'],
    unless  => "test -f ${base_dir}/${name}",
    require => File[$base_dir],
  }

  $storage_params = {
    device       => "${base_dir}/${name}",
    mnt_base_dir => $mnt_base_dir,
    byte_size    => $byte_size,
    subscribe    => Exec["create_partition-${name}"],
    loopback     => true,
  }
  # NOTE(mgagne) Puppet does not allow hash keys to be bare variables.
  #              Keep double-quotes to avoid parse errors.
  $device_config_hash = { "${name}" => $storage_params }
  create_resources("swift::storage::${fstype}", $device_config_hash)
}
