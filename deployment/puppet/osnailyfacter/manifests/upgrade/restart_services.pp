# Restart services only if upgraded packages matches the catalog

class osnailyfacter::upgrade::restart_services {
#  $mu_upgrade = hiera_hash('mu_upgrade', {})
#  if $mu_upgrade['enabled'] {
#    notify { 'restarting services': } ~> Service<||>
#  }

  $static_packages = hiera_hash('static_versions',{})
  $group_packages = hiera_hash('group_versions',{})

  $initial_group_hash = getpackagegrouphash($group_packages, {})
  $restart_on = comp_catalog(concat(keys($static_packages),keys($initial_group_hash)))
  if $restart_on { notify{'Restarting services': } ~> Service<||> }

}
