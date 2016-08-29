# prepares symlinks for choosen repos, which should be
# used for env update
class osnailyfacter::upgrade::prepare_symlinks {
  $mu_upgrade   = hiera_hash('mu_upgrade', {})
  $update_repos = split($mu_upgrade['repos'], ',')

  file { [ '/etc/fuel/', '/etc/fuel/maintenance/', '/etc/fuel/maintenance/apt/' ]:
    ensure  => 'directory',
  } ->

  file { '/etc/fuel/maintenance/apt/sources.list.d/':
    ensure  => 'directory',
    recurse => true,
    purge   => true,
  } ->

  ::osnailyfacter::upgrade::repo_symlink { $update_repos: }
}
