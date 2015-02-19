notice('MODULAR: dns-client.pp')

$management_vip     = hiera('management_vip')

class { 'osnailyfacter::resolvconf':
  management_vip => $management_vip,
}

