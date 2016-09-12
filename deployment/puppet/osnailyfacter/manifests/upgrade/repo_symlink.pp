# == Type: osnailyfacter::repo_symlink
#
# Creates symlink to "update repo" in special directory
#
define osnailyfacter::upgrade::repo_symlink () {

  $repo = strip($name)

  file { "symlink_repo-${repo}":
    ensure => 'link',
    path   => "/etc/fuel/maintenance/apt/sources.list.d/${repo}.list",
    target => "/etc/apt/sources.list.d/${repo}.list",
  }
}
