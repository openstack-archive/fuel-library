class osnailyfacter::netconfig::reserved_ports {

  notice('MODULAR: netconfig/reserved_ports.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  # setting kernel reserved ports
  # defaults are 35357,41055-41056,49000-49001,49152-49215,55572,58882
  class { '::openstack::reserved_ports': }

}
