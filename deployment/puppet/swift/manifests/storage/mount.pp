#
# Usage
#   swift::storage::mount
#
#
define swift::storage::mount(
  $device,
  $mnt_base_dir = '/srv/node',
  $loopback     = false
) {
  if($loopback){
    $options = 'noatime,nodiratime,nobarrier,logbufs=8,loop'
  } else {
    $options = 'noatime,nodiratime,nobarrier,logbufs=8'
  }
  # the directory that represents the mount point
  # needs to exist
  file { "${mnt_base_dir}/${name}":
    ensure => directory,
    owner  => 'swift',
    group  => 'swift',
  }

  mount { "${mnt_base_dir}/${name}":
    ensure  => present,
    device  => $device,
    fstype  => 'xfs',
    options => $options,
    require => File["${mnt_base_dir}/${name}"]
  }

  # double checks to make sure that things are mounted
  exec { "mount_${name}":
    command   => "mount ${mnt_base_dir}/${name}",
    path      => ['/bin'],
    require   => Mount["${mnt_base_dir}/${name}"],
    unless    => "grep ${mnt_base_dir}/${name} /etc/mtab",
    # TODO - this needs to be removed when I am done testing
    logoutput => true,
  }

  exec { "fix_mount_permissions_${name}":
    command     => "chown -R swift:swift ${mnt_base_dir}/${name}",
    path        => ['/usr/sbin', '/bin'],
    subscribe   => Exec["mount_${name}"],
    refreshonly => true,
  }
}
