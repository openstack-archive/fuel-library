notice('MODULAR: configure_default_route.pp')

$network_scheme = hiera('network_scheme')
$management_vrouter_vip = hiera('management_vrouter_vip')

prepare_network_config($network_scheme)
$management_int = get_network_role_property('management', 'interface')
$fw_admin_int = get_network_role_property('fw-admin', 'interface')
$ifconfig = configure_default_route($network_scheme, $management_vrouter_vip, $fw_admin_int, $management_int )

notice ($ifconfig)
