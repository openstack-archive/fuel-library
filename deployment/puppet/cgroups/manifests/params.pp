class cgroups::params {

  $cgconfig_path    = '/etc/cgconfig.conf'
  $cgrules_path     = '/etc/cgrules.conf'
  $cgroups_set      = {"nova-api"=>{"memory"=>{"memory.soft_limit_in_bytes"=>500}},"neutron-metadata-agent"=>{"memory"=>{"memory.soft_limit_in_bytes"=>500}}}
  $default_packages = ['cgroup-bin', 'libcgroup1']

  case $::osfamily {
    'Debian': {
      $packages = $default_packages
     }
  }
}
