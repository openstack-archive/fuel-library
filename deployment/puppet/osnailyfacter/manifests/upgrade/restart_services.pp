class osnailyfacter::upgrade::restart_services {
  $mu_upgrade = hiera_hash('mu_upgrade', {})
  $group_packages = hiera_hash('upgrade_packages',{})
  $extended_group_hash = getpackagegrouphash($group_packages,{})

  if $mu_upgrade['enabled'] {
    notify { 'restarting services': } ~> Service<||>
  } else {
    override_pkg_version($extended_group_hash)
  }
}
