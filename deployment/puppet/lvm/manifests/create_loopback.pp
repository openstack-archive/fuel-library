
class lvm::create_loopback(
  $volume_name     = 'nova-volumes',
  $size            = '2G',
  $loopback_device = '/dev/loop2'
) {

  Exec {
    cwd => '/tmp/',
  }

  exec { "/bin/dd if=/dev/zero of=${volume_name} bs=1 count=0 seek=${size}":
    unless => "/sbin/vgdisplay ${volume_name}"
  } ~>

  exec { "/sbin/losetup ${loopback_device} ${volume_name}":
    refreshonly => true,
  } 

}
