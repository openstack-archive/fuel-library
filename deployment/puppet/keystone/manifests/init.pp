#
# module for installing keystone
#
class keystone(
  $package_ensure  = 'present',
  $log_verbose     = 'False',
  $log_debug       = 'False',
  $default_store   = 'sqlite',
  $bind_host       = '0.0.0.0',
  $bind_port       = '5000',
  $admin_bind_host = '0.0.0.0',
  $admin_bind_port = '5001'
) {

  # this package dependency needs to be removed when it
  # is added as a package dependency
  # I filed the following ticket against the packages: 909941
  if(! defined(Package['python-migrate'])) {
    package { 'python-migrate':
      ensure => present,
    }
  }

  package { 'keystone':
    ensure => $package_ensure,
  }

  group { 'keystone':
    ensure => present,
  }
  user { 'keystone':
    ensure => 'present',
    gid    => 'keystone',
  }

  file { '/etc/keystone':
    ensure  => directory,
    owner   => 'keystone',
    group   => 'keystone',
    mode    => 0755,
    require => Package['keystone']
  }

  file { 'keystone.conf':
    path    => '/etc/keystone/keystone.conf',
    ensure  => present,
    owner   => 'keystone',
    mode    => 0600,
    content => template('keystone/keystone.conf.erb'),
    require => Package['keystone'],
    notify => Service['keystone'],
  }

  service { 'keystone':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

}
