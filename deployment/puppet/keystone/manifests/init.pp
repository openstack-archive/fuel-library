#
# module for installing keystone
#
class keystone(
  $package_ensure = 'present',
  $bind_host      = '0.0.0.0',
  $public_port    = '5000',
  $admin_port     = '35357',
  $admin_token    = 'service_token',
  $compute_port   = '3000',
  $log_verbose    = 'False',
  $log_debug      = 'False',
  $use_syslog     = 'False',
  $catalog_type   = 'template'
) {

  validate_re($catalog_type, 'template|sql')

  if ( $use_syslog != 'False') {
    fail('use syslog currently only accepts false')
  }

  include keystone::params
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

  concat { '/etc/keystone/keystone.conf':
    owner   => keystone,
    group   => keystone,
    mode    => 600,
    require => Package['keystone'],
    notify  => Service['keystone'],
  }

  # config sections
  keystone::config { 'DEFAULT':
    config => {
      'bind_host'    => $bind_host,
      'public_port'  => $public_port,
      'admin_port'   => $admin_port,
      'admin_token'  => $admin_token,
      'compute_port' => $compute_port,
      'log_verbose'  => $log_verbose,
      'log_debug'    => $log_debug,
      'use_syslog'   => $use_syslog
    },
    order  => '00',
  }

  keystone::config { 'identity':
    order  => '03',
  }

  if($catalog_type == 'template') {
    # if we are using a catalog, then I may want to manage the file
    keystone::config { 'template_catalog':
      order => '04',
    }
  } elsif($catalog_type == 'sql' ) {
    keystone::config { 'sql_catalog':
      order => '04',
    }
  }

  keystone::config { 'footer':
    order    => '99'
  }

  service { 'keystone':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    provider   => $::keystone::params::service_provider,
  }

}
