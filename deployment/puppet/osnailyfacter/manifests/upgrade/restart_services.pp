class osnailyfacter::upgrade::restart_services {
  $mu_upgrade = hiera_hash('mu_upgrade', {})
  $group_packages = hiera_hash('upgrade_packages',{})

  if $mu_upgrade['enabled'] {
    notify { 'restarting services': } ~> Service<||>
  }
  elsif !empty($group_packages) {
    $extended_group_hash = get_package_group_hash($group_packages)
    override_pkg_version($extended_group_hash)
  }
}
