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
  $admin_token    = 'service_token',
  $package_ensure = 'present',
  $bind_host      = '0.0.0.0',
  $public_port    = '5000',
  $admin_port     = '35357',
  $compute_port   = '3000',
  $log_verbose    = 'False',
  $log_debug      = 'False',
  $use_syslog     = 'False',
  $catalog_type   = 'sql',
  $backend_driver = 'keystone.token.backends.kvs.Token',
  $enabled        = true
) {

  validate_re($catalog_type, 'template|sql')
  File['/etc/keystone/keystone.conf'] -> Keystone_config<||> ~> Service['keystone']
  Keystone_config<||> -> Exec['keystone-manage db_sync']

  # TODO implement syslog features
  if ( $use_syslog != 'False') {
    fail('use syslog currently only accepts false')
  }

  include 'keystone::params'

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

  file { '/etc/keystone/keystone.conf':
    mode    => '0600',
  }

  # default config
  keystone_config {
    'DEFAULT/admin_token':  value => $admin_token;
    'DEFAULT/bind_host':    value => $bind_host;
    'DEFAULT/public_port':  value => $public_port;
    'DEFAULT/admin_port':   value => $admin_port;
    'DEFAULT/compute_port': value => $compute_port;
    'DEFAULT/verbose':      value => $log_verbose;
    'DEFAULT/debug':        value => $log_debug;
  }

  # db connection config
  keystone_config {
    'sql/connection':   value => $sql_connection;
    'sql/idle_timeout': value => $idle_timeout;
  }

  # configure based on the catalog backend
  if($catalog_type == 'template') {
    keystone_config {
      'catalog/driver':
        value => 'keystone.catalog.backends.templated.TemplatedCatalog';
      'catalog/template_file':
        value => '/etc/keystone/default_catalog.templates';
    }
  } elsif($catalog_type == 'sql' ) {
    keystone_config { 'catalog/driver':
      value => ' keystone.catalog.backends.sql.Catalog'
    }
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
      subscribe   => Package['keystone'],
    }
  }
}
