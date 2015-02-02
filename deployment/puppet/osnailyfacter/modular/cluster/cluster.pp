notice('MODULAR: cluster.pp')

class { '::cluster':
  internal_address  => hiera('internal_address'),
  unicast_addresses => ipsort(values(hiera('controller_internal_addresses'))),
}
