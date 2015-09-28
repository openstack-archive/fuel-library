notice('MODULAR: public_vip_ping.pp')

$run_ping_checker = hiera('run_ping_checker', true)
$network_scheme = hiera('network_scheme')
$ping_host_list = try_get_value($network_scheme, 'endpoints/br-ex/gateway', [])
$primary_controller = hiera('primary_controller')

if $run_ping_checker and $primary_controller {
  $vip = 'vip__public'

  cluster::virtual_ip_ping { $vip :
    host_list => $ping_host_list,
  }

}

