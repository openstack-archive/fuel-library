# == Type: osnailyfacter::update_repo
#
# Creates symlink to "update repo" in special directory
#
define osnailyfacter::fuel_pkgs::update_repo () {
  file { "update_repo-${name}":
    ensure => 'link',
    path   => "/etc/fuel/upgrades/mu/apt/sources.list.d/${name}.list",
    target => "/etc/apt/sources.list.d/${name}.list",
    require => File['/etc/fuel/maintenance/updates/apt/sources.list.d/']
  }
}
