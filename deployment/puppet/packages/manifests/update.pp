# == Class: packages::update
#
# This class can be included in any task and
# any role class to override the package ensure
# properties to values in the "packages" Hiera hash
# and to create new package instances for the update
# purposes.
#
# This resource will update the ensure values of all
# packages in the catalog and create new package instances
# for the installed packages to update them too.
#
# === Parameters:
#
# [*mode*]
#   How should this type work with additional packages?
#   "catalog", "generate", "update", "installed"
#   See the README file for the description.
#   Default: catalog
#
# [*packages*]
#   Limit the list of packages to update.
#   The empty list means no limitations.
#   Default: []
#
# [*enable*]
#   Enable or disable this class.
#   Default: true
#
# [*instances_provider*]
#   The list of installed packages providers considered
#   to mean the actual packages installed at the system.
#   It will be used in the "update" and "installed" modes.
#   Default: ['apt', 'apt_fuel', 'rpm', 'yum']
#
# [*generate_provider*]
#   Create new package instances with this provider.
#   Default: undef
#
# [*type*]
#   Create new package instances of this type.
#   Default: package
#
# [*package_versions*]
#   The Hash with package names and versions to install.
#   It will be taken from the Hiera key "packages" unless provided.
#
class packages::update (
  $mode = 'catalog',
  $packages = [],
  $enable = true,
  $instances_provider = ['apt', 'apt_fuel', 'rpm', 'yum'],
  $generate_provider = undef,
  $type = 'package',
  $package_versions = undef,
) {

  if $enable {
    if $package_versions {
      validate_hash($package_versions)
      $package_versions_real = $package_versions
    } else {
      $package_versions_real = hiera_hash('packages', { })
    }

    update_packages { 'update_packages' :
      versions           => $package_versions_real,
      packages           => $packages,
      mode               => $mode,
      type               => $type,
      instances_provider => $instances_provider,
      generate_provider  => $generate_provider,
    }
  }

}
