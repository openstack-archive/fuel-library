class osnailyfacter::cluster_haproxy::cluster_haproxy {

  notice('MODULAR: cluster_haproxy/cluster_haproxy.pp')

  $network_scheme      = hiera_hash('network_scheme', {})
  $management_vip      = hiera('management_vip')
  $database_vip        = hiera('database_vip', '')
  $service_endpoint    = hiera('service_endpoint', '')
  $primary_controller  = hiera('primary_controller')
  $haproxy_hash        = hiera_hash('haproxy', {})
  $external_lb         = hiera('external_lb', false)
  #FIXME(mattymo): Move colocations to a separate task
  $colocate_haproxy    = hiera('colocate_haproxy', false)
  $ssl_default_ciphers = hiera('ssl_default_ciphers', 'HIGH:!aNULL:!MD5:!kEDH')

  if !$external_lb {
    #FIXME(mattymo): Replace with only VIPs for roles assigned to this node
    $stats_ipaddresses          = delete_undef_values([$management_vip, $database_vip, $service_endpoint, '127.0.0.1'])

    class { '::cluster::haproxy':
      haproxy_maxconn      => '16000',
      haproxy_bufsize      => '32768',
      primary_controller   => $primary_controller,
      debug                => pick($haproxy_hash['debug'], hiera('debug', false)),
      other_networks       => direct_networks($network_scheme['endpoints']),
      stats_ipaddresses    => $stats_ipaddresses,
      colocate_haproxy     => $colocate_haproxy,
      ssl_default_ciphers  => $ssl_default_ciphers,
    }
  }

}
