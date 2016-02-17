notice('MODULAR: cgroups.pp')

$cgroups_config = hiera('cgroups', {})

# Task should not be failed if configuration was not propagated
unless empty($cgroups_config) {
  $cgroups_set = prepare_cgroups_hash($cgroups_config)
  class {'cgroups':
    cgroups_set => $cgroups_hash,
  }
}
