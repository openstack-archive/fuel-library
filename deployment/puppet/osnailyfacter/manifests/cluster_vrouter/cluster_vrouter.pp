class osnailyfacter::cluster_vrouter::cluster_vrouter {

  notice('MODULAR: cluster_vrouter/cluster_vrouter.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $network_scheme = hiera_hash('network_scheme', {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  class { '::cluster::vrouter_ocf':
    other_networks => direct_networks($network_scheme['endpoints']),
  }

}
