notice('MODULAR: configure_default_route.pp')

$network_scheme = hiera('network_scheme')
$master_ip = hiera('master_ip')
$management_vrouter_vip = hiera('management_vrouter_vip')

$ifconfig = configure_default_route($network_scheme, $master_ip, $management_vrouter_vip)

create_resources('l23network::l3::ifconfig', $ifconfig)


