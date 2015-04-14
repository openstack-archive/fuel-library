notice('MODULAR: cluster-vrouter.pp')

$network_scheme = hiera('network_scheme', {})

class { 'cluster::vrouter_ocf':
  primary_controller => hiera('primary_controller'),
  other_networks     => direct_networks($network_scheme['endpoints']),
}
