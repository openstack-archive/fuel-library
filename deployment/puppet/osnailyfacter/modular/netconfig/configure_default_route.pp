notice('MODULAR: configure_default_route.pp')

$network_scheme = hiera('network_scheme')

class { 'l23network' :}
prepare_network_config($network_scheme)
$sdn = configure_default_route()
notify {"SDN: ${sdn}": }

