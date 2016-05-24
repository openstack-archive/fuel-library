class osnailyfacter::cluster_haproxy::cluster_haproxy {

  notice('MODULAR: cluster_haproxy/cluster_haproxy.pp')

  $network_scheme     = hiera_hash('network_scheme', {})
  $management_vip     = hiera('management_vip')
  $database_vip       = hiera('database_vip', '')
  $service_endpoint   = hiera('service_endpoint', '')
  $primary_controller = hiera('primary_controller')
  $haproxy_hash       = hiera_hash('haproxy', {})
  $external_lb        = hiera('external_lb', false)
  #FIXME(mattymo): Move colocations to a separate task
  $colocate_haproxy   = hiera('colocate_haproxy', true)

  $default_cipher_list = [
    'ECDHE-RSA-AES128-GCM-SHA256',
    'ECDHE-ECDSA-AES128-GCM-SHA256',
    'ECDHE-RSA-AES256-GCM-SHA384',
    'ECDHE-ECDSA-AES256-GCM-SHA384',
    'DHE-RSA-AES128-GCM-SHA256',
    'DHE-DSS-AES128-GCM-SHA256',
    'kEDH+AESGCM',
    'ECDHE-RSA-AES128-SHA256',
    'ECDHE-ECDSA-AES128-SHA256',
    'ECDHE-RSA-AES128-SHA',
    'ECDHE-ECDSA-AES128-SHA',
    'ECDHE-RSA-AES256-SHA384',
    'ECDHE-ECDSA-AES256-SHA384',
    'ECDHE-RSA-AES256-SHA',
    'ECDHE-ECDSA-AES256-SHA',
    'DHE-RSA-AES128-SHA256',
    'DHE-RSA-AES128-SHA',
    'DHE-DSS-AES128-SHA256',
    'DHE-RSA-AES256-SHA256',
    'DHE-DSS-AES256-SHA',
    'DHE-RSA-AES256-SHA',
    'AES128-GCM-SHA256',
    'AES256-GCM-SHA384',
    'AES128-SHA256',
    'AES256-SHA256',
    'AES128-SHA',
    'AES256-SHA',
    'AES',
    'CAMELLIA',
    'DES-CBC3-SHA',
    '!aNULL',
    '!eNULL',
    '!EXPORT',
    '!DES',
    '!RC4',
    '!MD5',
    '!PSK',
    '!aECDH',
    '!EDH-DSS-DES-CBC3-SHA',
    '!EDH-RSA-DES-CBC3-SHA',
    '!KRB5-DES-CBC3-SHA',
  ]
  $cipher_list = pick($haproxy_hash['cipher_list'], $default_cipher_list)

  if !$external_lb {
    #FIXME(mattymo): Replace with only VIPs for roles assigned to this node
    $stats_ipaddresses          = delete_undef_values([$management_vip, $database_vip, $service_endpoint, '127.0.0.1'])

    class { '::cluster::haproxy':
      haproxy_maxconn    => '16000',
      haproxy_bufsize    => '32768',
      primary_controller => $primary_controller,
      debug              => pick($haproxy_hash['debug'], hiera('debug', false)),
      other_networks     => direct_networks($network_scheme['endpoints']),
      stats_ipaddresses  => $stats_ipaddresses,
      colocate_haproxy   => $colocate_haproxy,
      cipher_list        => $cipher_list,
    }
  }

}
