# == Class: cinder::api
#
# Setup and configure the cinder API endpoint
#
# === Parameters
#
# [*keystone_password*]
#   The password to use for authentication (keystone)
#
# [*keystone_enabled*]
#   (optional) Use keystone for authentification
#   Defaults to true
#
# [*keystone_tenant*]
#   (optional) The tenant of the auth user
#   Defaults to services
#
# [*keystone_user*]
#   (optional) The name of the auth user
#   Defaults to cinder
#
# [*keystone_auth_host*]
#   (optional) The keystone host
#   Defaults to localhost
#
# [*keystone_auth_port*]
#   (optional) The keystone auth port
#   Defaults to 35357
#
# [*keystone_auth_protocol*]
#   (optional) The protocol used to access the auth host
#   Defaults to http.
#
# [*os_region_name*]
#   (optional) Some operations require cinder to make API requests
#   to Nova. This sets the keystone region to be used for these
#   requests. For example, boot-from-volume.
#   Defaults to undef.
#
# [*keystone_auth_admin_prefix*]
#   (optional) The admin_prefix used to admin endpoint of the auth host
#   This allow admin auth URIs like http://auth_host:35357/keystone.
#   (where '/keystone' is the admin prefix)
#   Defaults to false for empty. If defined, should be a string with a
#   leading '/' and no trailing '/'.
#
# [*service_port*]
#   (optional) The cinder api port
#   Defaults to 5000
#
# [*package_ensure*]
#   (optional) The state of the package
#   Defaults to present
#
# [*bind_host*]
#   (optional) The cinder api bind address
#   Defaults to 0.0.0.0
#
# [*enabled*]
#   (optional) The state of the service
#   Defaults to true
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*ratelimits*]
#   (optional) The state of the service
#   Defaults to undef. If undefined the default ratelimiting values are used.
#
# [*ratelimits_factory*]
#   (optional) Factory to use for ratelimiting
#   Defaults to 'cinder.api.v1.limits:RateLimitingMiddleware.factory'
#
class cinder::api (
  $keystone_password,
  $keystone_enabled           = true,
  $keystone_tenant            = 'services',
  $keystone_user              = 'cinder',
  $keystone_auth_host         = 'localhost',
  $keystone_auth_port         = '35357',
  $keystone_auth_protocol     = 'http',
  $keystone_auth_admin_prefix = false,
  $keystone_auth_uri          = false,
  $os_region_name             = undef,
  $service_port               = '5000',
  $package_ensure             = 'present',
  $bind_host                  = '0.0.0.0',
  $enabled                    = true,
  $manage_service             = true,
  $ratelimits                 = undef,
  $ratelimits_factory =
    'cinder.api.v1.limits:RateLimitingMiddleware.factory'
) {

  include cinder::params

  Cinder_config<||> ~> Service['cinder-api']
  Cinder_api_paste_ini<||> ~> Service['cinder-api']

  if $::cinder::params::api_package {
    Package['cinder-api'] -> Cinder_config<||>
    Package['cinder-api'] -> Cinder_api_paste_ini<||>
    Package['cinder-api'] ~> Service['cinder-api']
    Package['cinder']     ~> Service['cinder-api']
    package { 'cinder-api':
      ensure  => $package_ensure,
      name    => $::cinder::params::api_package,
    }
  }

  if $enabled {

    Cinder_config<||> ~> Exec['cinder-manage db_sync']

    exec { 'cinder-manage db_sync':
      command     => $::cinder::params::db_sync_command,
      path        => '/usr/bin',
      user        => 'cinder',
      refreshonly => true,
      logoutput   => 'on_failure',
      require     => Package['cinder'],
    }
    if $manage_service {
      $ensure = 'running'
    }
  } else {
    if $manage_service {
      $ensure = 'stopped'
    }
  }

  service { 'cinder-api':
    ensure    => $ensure,
    name      => $::cinder::params::api_service,
    enable    => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  cinder_config {
    'DEFAULT/osapi_volume_listen': value => $bind_host
  }

  if $os_region_name {
    cinder_config {
      'DEFAULT/os_region_name': value => $os_region_name;
    }
  }

  if $keystone_auth_uri {
    cinder_api_paste_ini { 'filter:authtoken/auth_uri': value => $keystone_auth_uri; }
  } else {
    cinder_api_paste_ini { 'filter:authtoken/auth_uri': value => "${keystone_auth_protocol}://${keystone_auth_host}:${service_port}/"; }
  }

  if $keystone_enabled {
    cinder_config {
      'DEFAULT/auth_strategy':     value => 'keystone' ;
    }
    cinder_api_paste_ini {
      'filter:authtoken/service_protocol':  value => $keystone_auth_protocol;
      'filter:authtoken/service_host':      value => $keystone_auth_host;
      'filter:authtoken/service_port':      value => $service_port;
      'filter:authtoken/auth_protocol':     value => $keystone_auth_protocol;
      'filter:authtoken/auth_host':         value => $keystone_auth_host;
      'filter:authtoken/auth_port':         value => $keystone_auth_port;
      'filter:authtoken/admin_tenant_name': value => $keystone_tenant;
      'filter:authtoken/admin_user':        value => $keystone_user;
      'filter:authtoken/admin_password':    value => $keystone_password, secret => true;
    }

  if ($ratelimits != undef) {
    cinder_api_paste_ini {
      'filter:ratelimit/paste.filter_factory': value => $ratelimits_factory;
      'filter:ratelimit/limits':               value => $ratelimits;
    }
  }

    if $keystone_auth_admin_prefix {
      validate_re($keystone_auth_admin_prefix, '^(/.+[^/])?$')
      cinder_api_paste_ini {
        'filter:authtoken/auth_admin_prefix': value => $keystone_auth_admin_prefix;
      }
    } else {
      cinder_api_paste_ini {
        'filter:authtoken/auth_admin_prefix': ensure => absent;
      }
    }
  }
}
