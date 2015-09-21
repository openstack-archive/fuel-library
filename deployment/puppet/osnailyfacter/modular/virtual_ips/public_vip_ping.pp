notice('MODULAR: public_vip_ping.pp')

prepare_network_config(hiera('network_scheme', {}))
$run_ping_checker = hiera('run_ping_checker', true)
$network_scheme = hiera('network_scheme')
$public_iface = get_network_role_property('public/vip', 'interface')
$ping_host_list = $network_scheme['endpoints'][$public_iface]['gateway']

if $run_ping_checker {
  $vip = 'vip__public'

  cluster::virtual_ip_ping { $vip :
    host_list => $ping_host_list,
  }

}

