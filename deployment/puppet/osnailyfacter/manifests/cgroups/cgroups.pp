class osnailyfacter::cgroups::cgroups {

  notice('MODULAR: cgroups/cgroups.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $cgroups_config = hiera('cgroups', {})
  $cgroups_set = prepare_cgroups_hash($cgroups_config)

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  # Task should not be failed if configuration was not propagated
  unless empty($cgroups_set) {
    class { '::cgroups':
      cgroups_set => $cgroups_set,
    }
  }

}
