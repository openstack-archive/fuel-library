#
# base glacne config.
#
# == parameters
#   * package_ensure - ensure state for package.
#
class glance(
  $package_ensure = 'present'
) {

  include glance::params

  file { '/etc/glance/':
    ensure  => directory,
    owner   => 'glance',
    group   => 'root',
    mode    => '0770',
    require => Package['glance']
  }
  package { 'glance':
    ensure => $package_ensure,
    name   => $::glance::params::package_name,
  }
}
