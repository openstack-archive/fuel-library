notice('MODULAR: cluster-vrouter.pp')

$network_scheme = hiera('network_scheme', {})

cluster::namespace_ocf { 'vrouter':
  primary_controller  => hiera('primary_controller'),
  host_interface      => 'vrouter-host',
  namespace_interface => 'vr-ns',
  host_ip             => '240.0.0.5',
  namespace_ip        => '240.0.0.6',
  other_networks      => direct_networks($network_scheme['endpoints']),
}
