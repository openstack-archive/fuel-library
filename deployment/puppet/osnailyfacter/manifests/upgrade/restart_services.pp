class osnailyfacter::upgrade::restart_services {
  $mu_upgrade = hiera_hash('mu_upgrade', {})
  $static_packages = hiera_hash('static_versions',{})
  $group_packages = hiera_hash('group_versions',{})
  $initial_group_hash = getpackagegrouphash($group_packages, $static_packages)

  if $mu_upgrade['enabled'] {
    notify { 'restarting services': } ~> Service<||>
  } else {
    $pkg_hash = deep_merge($initial_group_hash, $static_packages)
    override_pkg_version($pkg_hash)
  }
}
