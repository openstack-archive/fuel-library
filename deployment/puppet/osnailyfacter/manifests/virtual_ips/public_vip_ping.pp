class osnailyfacter::virtual_ips::public_vip_ping {

  notice('MODULAR: virtual_ips/public_vip_ping.pp')

  $network_scheme = hiera_hash('network_scheme', {})
  prepare_network_config($network_scheme)
  $run_ping_checker = hiera('run_ping_checker', true)
  $public_iface = get_network_role_property('public/vip', 'interface')
  $ping_host_list = $network_scheme['endpoints'][$public_iface]['gateway']

  if $run_ping_checker {
    $vip = 'vip__public'

    cluster::virtual_ip_ping { $vip :
      host_list => $ping_host_list,
    }

  }

}
