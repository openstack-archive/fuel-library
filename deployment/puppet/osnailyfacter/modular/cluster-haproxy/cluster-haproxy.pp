notice('MODULAR: cluster-haproxy.pp')

$network_scheme     = hiera('network_scheme', {})
$management_vip     = hiera('management_vip')
$primary_controller = hiera('primary_controller')
$stats_vip          = $management_vip

class { 'cluster::haproxy':
  haproxy_maxconn    => '16000',
  haproxy_bufsize    => '32768',
  primary_controller => $primary_controller,
  debug              => hiera('debug', false),
  other_networks     => direct_networks($network_scheme['endpoints']),
  stats_ipaddresses  => [$stats_vip, '127.0.0.1']
}
