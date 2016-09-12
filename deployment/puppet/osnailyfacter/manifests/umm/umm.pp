class osnailyfacter::umm::umm {

  notice('MODULAR: umm/umm.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  class { '::umm': }

}
