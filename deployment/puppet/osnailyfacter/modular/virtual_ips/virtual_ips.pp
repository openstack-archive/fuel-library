notice('MODULAR: virtual_ips.pp')

$network_scheme   = hiera('network_scheme')
$network_metadata = hiera('network_metadata')

prepare_network_config($network_scheme)
generate_vips($network_metadata)
