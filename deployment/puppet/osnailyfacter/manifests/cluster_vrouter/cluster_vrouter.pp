class osnailyfacter::cluster_vrouter::cluster_vrouter {

  notice('MODULAR: cluster_vrouter/cluster_vrouter.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  $network_scheme = hiera_hash('network_scheme', {})

  class { '::cluster::vrouter_ocf':
    other_networks => direct_networks($network_scheme['endpoints']),
  }

}
