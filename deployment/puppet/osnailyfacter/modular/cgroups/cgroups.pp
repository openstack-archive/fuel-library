notice('MODULAR: cgroups.pp')

$cgroups_config = hiera('cgroups')

# Task should not be failed if configuration was not propagated
if ($cgroups_config) {
  $cgroups_hash = prepare_cgroups_hash($cgroups_config)
  class {'cgroups':
    cgroups_hash => $cgroups_hash,
  }
}
