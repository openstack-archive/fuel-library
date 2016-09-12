class osnailyfacter::virtual_ips::virtual_ips {

  notice('MODULAR: virtual_ips/virtual_ips.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $network_metadata = hiera_hash('network_metadata', {})
  $network_scheme = hiera_hash('network_scheme', {})
  $roles = hiera('roles')

  $vips = generate_vips($network_metadata, $network_scheme, $roles)

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  create_resources('cluster::virtual_ip', $vips)
}
