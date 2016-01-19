notice('MODULAR: virtual_ips.pp')

$network_metadata = hiera_hash('network_metadata', {})
$network_scheme = hiera_hash('network_scheme', {})
$roles = hiera('roles')

generate_vips($network_metadata, $network_scheme, $roles)
