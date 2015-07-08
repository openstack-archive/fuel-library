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
# [*volume_path*]
#   Volume image location. Defaults to '/var/lib/cinder'.
class cinder::setup_test_volume(
  $volume_name     = 'cinder-volumes',
  $volume_path     = '/var/lib/cinder',
  $size            = '4G',
  $loopback_device = '/dev/loop2'
) {

  package { 'lvm2':
    ensure => present,
  } ~>

  file { $volume_path:
    ensure  => directory,
    owner   => 'cinder',
    group   => 'cinder',
    require => Package['cinder'],
  } ~>

  exec { "create_${volume_path}/${volume_name}":
    command => "dd if=/dev/zero of=\"${volume_path}/${volume_name}\" bs=1 count=0 seek=${size}",
    path    => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    unless  => "stat ${volume_path}/${volume_name}",
  } ~>

  exec { "losetup ${loopback_device} ${volume_path}/${volume_name}":
    path        => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    refreshonly => true,
  } ~>

  exec { "pvcreate ${loopback_device}":
    path        => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    unless      => "pvdisplay | grep ${volume_name}",
    refreshonly => true,
  } ~>

  exec { "vgcreate ${volume_name} ${loopback_device}":
    path        => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    refreshonly => true,
  }

}

