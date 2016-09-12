class osnailyfacter::dns::dns_client {

  notice('MODULAR: dns/dns_client.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  $management_vip = hiera('management_vrouter_vip')

  class { '::osnailyfacter::resolvconf':
    management_vip => $management_vip,
  }

}
