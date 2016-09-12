class osnailyfacter::virtual_ips::virtual_ips {

  notice('MODULAR: virtual_ips/virtual_ips.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $network_metadata = hiera_hash('network_metadata', {})
  $network_scheme = hiera_hash('network_scheme', {})
  $roles = hiera('roles')

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  generate_vips($network_metadata, $network_scheme, $roles)
}
