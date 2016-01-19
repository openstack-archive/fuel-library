notice('MODULAR: cluster-vrouter.pp')

$network_scheme = hiera_hash('network_scheme', {})

class { 'cluster::vrouter_ocf':
  other_networks => direct_networks($network_scheme['endpoints']),
}
