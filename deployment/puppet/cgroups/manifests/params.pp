class cgroups::params {

  case $::osfamily {
    'Debian': {
      $packages = ['cgroup-bin', 'libcgroup1']
    }
    default: {
      fail("Unsupported platform")
    }
  }

}
