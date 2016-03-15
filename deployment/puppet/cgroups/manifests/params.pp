class cgroups::params {

  case $::osfamily {
    'Debian': {
      $packages = ['cgroup-bin', 'libcgroup1', 'cgroup-upstart']
    }
    default: {
      fail("Unsupported platform")
    }
  }
}
