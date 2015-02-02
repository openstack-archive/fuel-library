class { '::cluster':
  internal_address  => hiera('internal_address'),
  unicast_addresses => hiera('controller_internal_addresses'),
}
