notice('MODULAR: cluster-haproxy.pp')

$network_scheme     = hiera_hash('network_scheme', {})
$management_vip     = hiera('management_vip')
$database_vip       = hiera('database_vip', '')
$service_endpoint   = hiera('service_endpoint', '')
$primary_controller = hiera('primary_controller')
$haproxy_hash       = hiera_hash('haproxy', {})
$external_lb        = hiera('external_lb', false)

if !$external_lb {
  #FIXME(mattymo): Replace with only VIPs for roles assigned to this node
  $stats_ipaddresses          = delete_undef_values([$management_vip, $database_vip, $service_endpoint, '127.0.0.1'])

  class { 'cluster::haproxy':
    haproxy_maxconn    => '16000',
    haproxy_bufsize    => '32768',
    primary_controller => $primary_controller,
    debug              => pick($haproxy_hash['debug'], hiera('debug', false)),
    other_networks     => direct_networks($network_scheme['endpoints']),
    stats_ipaddresses  => $stats_ipaddresses
  }
}
