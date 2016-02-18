class cgroups::params {

  $cgconfig_path  = '/etc/cgconfig.conf'
  $cgrules_path   = '/etc/cgrules.conf'
  $cgroups_set    = prepare_cgroups_hash(hiera('cgroups'))
  $packages       = ['cgroup-bin', 'libcgroup1']
  $srv            = join(keys($cgroups_set), ' ')
}
