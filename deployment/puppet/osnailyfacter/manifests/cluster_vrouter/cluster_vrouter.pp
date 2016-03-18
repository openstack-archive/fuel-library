class osnailyfacter::cluster_vrouter::cluster_vrouter {

  notice('MODULAR: cluster_vrouter/cluster_vrouter.pp')

  $network_scheme = hiera_hash('network_scheme', {})

  class { '::cluster::vrouter_ocf':
    other_networks => direct_networks($network_scheme['endpoints']),
  }

}
