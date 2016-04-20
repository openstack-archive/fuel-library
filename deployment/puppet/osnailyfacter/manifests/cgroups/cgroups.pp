class osnailyfacter::cgroups::cgroups {

  notice('MODULAR: cgroups/cgroups.pp')

  $cgroups_config = hiera('cgroups', {})
  $cgroups_set = prepare_cgroups_hash($cgroups_config)

  # Task should not be failed if configuration was not propagated
  unless empty($cgroups_set) {
    class { '::cgroups':
      cgroups_set => $cgroups_set,
    }
  }

}
