notice('MODULAR: virtual_ips.pp')

$network_metadata = hiera_hash('network_metadata')
$network_scheme = hiera_hash('network_scheme')
$role = hiera('role')

generate_vips($network_metadata, $network_scheme, $role)
