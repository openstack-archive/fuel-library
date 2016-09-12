class osnailyfacter::netconfig::reserved_ports {

  notice('MODULAR: netconfig/reserved_ports.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  # setting kernel reserved ports
  # defaults are 35357,41055-41056,49000-49001,49152-49215,55572,58882
  class { '::openstack::reserved_ports': }

}
