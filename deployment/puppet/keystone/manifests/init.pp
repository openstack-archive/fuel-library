#
# Module for managing keystone config.
#
# == Parameters
#
#   [package_ensure] Desired ensure state of packages. Optional. Defaults to present.
#     accepts latest or specific versions.
#   [bind_host] Host that keystone binds to.
#   [bind_port]
#   [public_port]
#   [admin_port] Port that can be used for admin tasks.
#   [admin_token] Admin token that can be used to authenticate as a keystone
#     admin.
#   [compute_port] TODO
#   [log_verbose] Rather keystone should log at verbose level. Optional.
#     Defaults to False.
#   [log_debug] Rather keystone should log at debug level. Optional.
#     Defaults to False.
#   [use_syslog] Rather or not keystone should log to syslog. Optional.
#     Defaults to False.
#   [catalog_type]
#
# == Dependencies
#  None
#
# == Examples
#
#   class { 'keystone':
#     log_verbose => 'True',
#     admin_token => 'my_special_token',
#   }
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
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
  $catalog_type   = 'sql',
  $backend_driver = 'keystone.token.backends.kvs.Token',
  $enabled        = true
) {

  validate_re($catalog_type, 'template|sql')

  # TODO implement syslog features
  if ( $use_syslog != 'False') {
    fail('use syslog currently only accepts false')
  }

  include 'keystone::params'
  include 'concat::setup'

  package { 'keystone':
    name   => $::keystone::params::package_name,
    ensure => $package_ensure,
  }

  group { 'keystone':
    ensure  => present,
    system  => true,
    require => Package['keystone'],
  }

  user { 'keystone':
    ensure  => 'present',
    gid     => 'keystone',
    system  => true,
    require => Package['keystone'],
  }

  file { '/etc/keystone':
    ensure  => directory,
    owner   => 'keystone',
    group   => 'keystone',
    mode    => 0755,
    require => Package['keystone']
  }

  concat { '/etc/keystone/keystone.conf':
    owner   => 'keystone',
    group   => 'keystone',
    mode    => '0600',
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
      'use_syslog'   => $use_syslog,
      'backend_driver' => $backend_driver,
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

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'keystone':
    name       => $::keystone::params::service_name,
    ensure     => $service_ensure,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    provider   => $::keystone::params::service_provider,
  }

  if $enabled {
    # this probably needs to happen more often than just when the db is
    # created
    exec { 'keystone-manage db_sync':
      path        => '/usr/bin',
      refreshonly => true,
      notify      => Service['keystone'],
      subscribe   => [Package['keystone'], Concat['/etc/keystone/keystone.conf']]
    }
  }
}
