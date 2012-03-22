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
    name   => $::glance::params::package_name,
    ensure => $package_ensure,
  }
  if(! defined(Package['python-migrate'])) {
    package { 'python-migrate': ensure => 'present' }
  }
}
