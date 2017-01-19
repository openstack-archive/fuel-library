class osnailyfacter::create_resources {

  notice('MODULAR: astute/create_resources.pp')

  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
    create        => true,
  }

}
