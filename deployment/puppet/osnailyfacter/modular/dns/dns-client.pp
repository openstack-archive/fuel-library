notice('MODULAR: dns-client.pp')

$management_vip = hiera('management_vrouter_vip')

class { 'osnailyfacter::resolvconf':
  management_vip => $management_vip,
}

