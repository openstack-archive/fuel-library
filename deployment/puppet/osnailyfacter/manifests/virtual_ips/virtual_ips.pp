class osnailyfacter::virtual_ips::virtual_ips {

  notice('MODULAR: virtual_ips/virtual_ips.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  $network_metadata = hiera_hash('network_metadata', {})
  $network_scheme = hiera_hash('network_scheme', {})
  $roles = hiera('roles')

  $vips = generate_vips($network_metadata, $network_scheme, $roles)
  create_resources('cluster::virtual_ip', $vips)
}
