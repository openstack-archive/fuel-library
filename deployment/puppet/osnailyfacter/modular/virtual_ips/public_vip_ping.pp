notice('MODULAR: public_vip_ping.pp')

$run_ping_checker = hiera('run_ping_checker', true)
$network_scheme = hiera('network_scheme')
$ping_host_list = $network_scheme['endpoints']['br-ex']['gateway']

if $run_ping_checker {
  $vip = 'vip__public'

  cluster::virtual_ip_ping { $vip :
    host_list => $ping_host_list,
  }

}

