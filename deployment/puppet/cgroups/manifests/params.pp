class cgroups::params {

  $cgconfig_path    = '/etc/cgconfig.conf'
  $cgrules_path     = '/etc/cgrules.conf'
  $cgroups_set      = {}
  $default_packages = ['cgroup-bin', 'libcgroup1']

  case $::osfamily {
    'Debian': {
      $packages = $default_packages
     }
    default: {
      fail("Unsupported platform: ${::operatingsystem}")
    }
  }
}
