# Forming and creating package resources to upgrade

define osnailyfacter::upgrade::pkgs () {
  $ensure_attribute = "ensure" # This is a parameter for package_resource
  $static_packages  = hiera_hash('static_versions',{})
  $group_packages   = hiera_hash('group_versions',{})
  validate_hash($static_packages)
  validate_hash($group_packages)

  notice("Proceed with the following hash of packages: ")
  notice($static_packages)
  notice($group_packages)

  # Create a hash for static_packages
  $static_packages_hash = hash(zip(keys($static_packages), getarrayhash("$ensure_attribute",values($static_packages))))
  notice("Resulted static_packages_hash to implement:")
  notice($static_packages_hash)
  validate_hash($static_packages_hash)

  # Create a hash for package groups
  $initial_group_hash = getpackagegrouphash($group_packages, keys($static_packages))
  $group_packages_hash = hash(zip(keys($initial_group_hash), getarrayhash("$ensure_attribute",values($initial_group_hash))))
  notice("Resulted groups_packages_hash to implement:")
  notice($group_packages_hash)
  validate_hash($group_packages_hash)

  create_resources(package, $static_packages_hash)
  create_resources(package, $group_packages_hash)
}
