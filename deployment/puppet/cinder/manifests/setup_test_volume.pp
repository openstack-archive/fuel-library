# == Class: cinder::setup_test_volume
#
# Setup a volume group on a loop device for test purposes.
#
# === Parameters
#
# [*volume_name*]
#   Volume group name. Defaults to 'cinder-volumes'.
#
# [*size*]
#   Volume group size. Defaults to '4G'.
#
# [*loopback_device*]
#   Loop device name. Defaults to '/dev/loop2'.
#
class cinder::setup_test_volume(
  $volume_name     = 'cinder-volumes',
  $size            = '4G',
  $loopback_device = '/dev/loop2'
) {

  Exec {
    cwd => '/tmp/',
  }

  package { 'lvm2':
    ensure => present,
  } ~>

  exec { "/bin/dd if=/dev/zero of=${volume_name} bs=1 count=0 seek=${size}":
    unless => "/sbin/vgdisplay ${volume_name}"
  } ~>

  exec { "/sbin/losetup ${loopback_device} ${volume_name}":
    refreshonly => true,
  } ~>

  exec { "/sbin/pvcreate ${loopback_device}":
    refreshonly => true,
  } ~>

  exec { "/sbin/vgcreate ${volume_name} ${loopback_device}":
    refreshonly => true,
  }

}

