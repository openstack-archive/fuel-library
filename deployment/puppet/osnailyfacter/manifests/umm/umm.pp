class osnailyfacter::umm::umm {

  notice('MODULAR: umm/umm.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  class { '::umm': }

}
