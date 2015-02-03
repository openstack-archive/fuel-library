class nailgun::loopback
{

  $loopback_devices = {
    '1' => {'loopdev' => 1},
    '2' => {'loopdev' => 2},
    '3' => {'loopdev' => 3},
    '4' => {'loopdev' => 4},
    '5' => {'loopdev' => 5},
    '6' => {'loopdev' => 6},
    '7' => {'loopdev' => 7},
    '8' => {'loopdev' => 8},
    '9' => {'loopdev' => 9},}
  create_resources(nailgun::loopback::create, $loopback_devices)
}

define nailgun::loopback::create($loopdev) {
  validate_re($loopdev, '^\d+$')
  exec { "mknod -m 0660 /dev/loop${loopdev} b 7 ${loopdev}; chown root:disk
/dev/loop${loopdev}":
    creates => "/dev/loop${loopdev}",
    path => ["/sbin", "/usr/sbin", "/bin", "/usr/bin"]
  }
}
