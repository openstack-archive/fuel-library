# follow the instructions for creating a loopback device
# for storage from: http://swift.openstack.org/development_saio.html
#
#
# creates a managed loopback interface
#   - creates a file
#   - formats the file to be an xfs device and mounts it as a loopback device at /srv/node/$name
#   - sets up each mount point as a swift endpoint
define swift::storage::loopback(
  $base_dir  = '/srv/loopback-device',
  $mnt_base_dir = '/srv/node',
  $byte_size = '1024',
  $seek      = '25000'
) {

  if(!defined(File[$base_dir])) {
    file { $base_dir:
      ensure => directory,
    }
  }

  if(!defined(File[$mnt_base_dir])) {
    file { $mnt_base_dir:
      owner  => 'swift',
      group  => 'swift',
      ensure => directory,
    }
  }

  exec { "create_partition-${name}":
    command     => "dd if=/dev/zero of=${base_dir}/${name} bs=${byte_size} count=0 seek=${seek}",
    path        => ['/usr/bin/', '/bin'],
    unless      => "test -f ${base_dir}/${name}",
    require     => File[$base_dir],
  }

  swift::storage::xfs { $name:
    device       => "${base_dir}/${name}",
    mnt_base_dir => $mnt_base_dir,
    byte_size    => $byte_size,
    subscribe    => Exec["create_partition-${name}"],
  }

}
