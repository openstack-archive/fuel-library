notice('MODULAR: cluster-haproxy.pp')

$network_scheme     = hiera('network_scheme', {})
$management_vip     = hiera('management_vip')
$database_vip       = hiera('database_vip', '')
$service_endpoint   = hiera('service_endpoint', '')
$primary_controller = hiera('primary_controller')

#FIXME(mattymo): Replace with only VIPs for roles assigned to this node
$stats_ipaddresses          = delete_undef_values([$management_vip, $database_vip, $service_endpoint, '127.0.0.1'])

cluster::namespace_ocf { 'haproxy':
  primary_controller  => hiera('primary_controller'),
  host_interface      => 'hapr-host',
  namespace_interface => 'hapr-ns',
  host_ip             => '240.0.0.1',
  namespace_ip        => '240.0.0.2',
  other_networks      => direct_networks($network_scheme['endpoints']),
} ->

class { 'cluster::haproxy':
  haproxy_maxconn    => '16000',
  haproxy_bufsize    => '32768',
  primary_controller => $primary_controller,
  debug              => hiera('debug', false),
  other_networks     => direct_networks($network_scheme['endpoints']),
  stats_ipaddresses  => $stats_ipaddresses
}

