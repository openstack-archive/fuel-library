class osnailyfacter::upgrade::upgrade {
  $mu_upgrade = hiera_hash('mu_upgrade', {})
  if $mu_upgrade['enabled'] {
    notify { 'restarting services': } ~> Service<||>
  }
}
