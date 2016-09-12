class osnailyfacter::dns::dns_client {

  notice('MODULAR: dns/dns_client.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $management_vip = hiera('management_vrouter_vip')

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  class { '::osnailyfacter::resolvconf':
    management_vip => $management_vip,
  }

}
