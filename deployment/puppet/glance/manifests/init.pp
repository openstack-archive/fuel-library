class glance(
  $package_ensure = 'present'
) {
  file { '/etc/glance/':
    ensure  => directory,
    owner   => 'glance',
    group   => 'root',
    mode    => '0770',
    require => Package['glance']
  }
  package { 'glance': ensure => $package_ensure }
}
