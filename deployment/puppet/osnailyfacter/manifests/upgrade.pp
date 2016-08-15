class osnailyfacter::upgrade {
  $mu_upgrade = hiera('mu_upgrade', false)
  if $mu_upgrade {
    notify { 'restarting services': } ~> Service<||>
  }
}
