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
#   (optional) DEPRECATED The keystone host
#   Defaults to localhost
#   Use auth_uri instead.
#
# [*keystone_auth_port*]
#   (optional) DEPRECATED The keystone auth port
#   Defaults to 35357
#   Use auth_uri instead.
#
# [*keystone_auth_protocol*]
#   (optional) DEPRECATED The protocol used to access the auth host
#   Defaults to http.
#   Use auth_uri instead.
#
# [*os_region_name*]
#   (optional) Some operations require cinder to make API requests
#   to Nova. This sets the keystone region to be used for these
#   requests. For example, boot-from-volume.
#   Defaults to undef.
#
# [*keystone_auth_admin_prefix*]
#   (optional) DEPRECATED The admin_prefix used to admin endpoint of the auth
#   host. This allow admin auth URIs like http://auth_host:35357/keystone.
#   (where '/keystone' is the admin prefix)
#   Defaults to false for empty. If defined, should be a string with a
#   leading '/' and no trailing '/'.
#   Use auth_uri instead.
#
# [*keystone_auth_uri*]
#   (optional) DEPRECATED Renamed to auth_uri
#   Defaults to 'false'.
#
# [*auth_uri*]
#   (optional) Public Identity API endpoint.
#   Defaults to 'false'.
#
# [*identity_uri*]
#   (optional) Complete admin Identity API endpoint.
#   Defaults to: false
#
# [*service_port*]
#   (optional) DEPRECATED The Keystone public api port
#   Defaults to 5000
#
# [*service_workers*]
#   (optional) Number of cinder-api workers
#   Defaults to $::processorcount
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
# [*default_volume_type*]
#   (optional) default volume type to use.
#   This should contain the name of the default volume type to use.
#   If not configured, it produces an error when creating a volume
#   without specifying a type.
#   Defaults to 'false'.
#
# [*validate*]
#   (optional) Whether to validate the service is working after any service refreshes
#   Defaults to false
#
# [*validation_options*]
#   (optional) Service validation options
#   Should be a hash of options defined in openstacklib::service_validation
#   If empty, defaults values are taken from openstacklib function.
#   Default command list volumes.
#   Require validate set at True.
#   Example:
#   glance::api::validation_options:
#     glance-api:
#       command: check_cinder-api.py
#       path: /usr/bin:/bin:/usr/sbin:/sbin
#       provider: shell
#       tries: 5
#       try_sleep: 10
#   Defaults to {}
#
# [*sync_db*]
#   (Optional) Run db sync on the node.
#   Defaults to true
#
class cinder::api (
  $keystone_password,
  $keystone_enabled           = true,
  $keystone_tenant            = 'services',
  $keystone_user              = 'cinder',
  $auth_uri                   = false,
  $identity_uri               = false,
  $os_region_name             = undef,
  $service_workers            = $::processorcount,
  $package_ensure             = 'present',
  $bind_host                  = '0.0.0.0',
  $enabled                    = true,
  $manage_service             = true,
  $ratelimits                 = undef,
  $default_volume_type        = false,
  $ratelimits_factory =
    'cinder.api.v1.limits:RateLimitingMiddleware.factory',
  $validate                   = false,
  $sync_db                    = true,
  # DEPRECATED PARAMETERS
  $validation_options         = {},
  $keystone_auth_uri          = false,
  $keystone_auth_host         = 'localhost',
  $keystone_auth_port         = '35357',
  $keystone_auth_protocol     = 'http',
  $keystone_auth_admin_prefix = false,
  $service_port               = '5000',
) {

  include ::cinder::params
  include ::cinder::policy

  Cinder_config<||> ~> Service['cinder-api']
  Cinder_api_paste_ini<||> ~> Service['cinder-api']
  Class['cinder::policy'] ~> Service['cinder-api']

  if $::cinder::params::api_package {
    Package['cinder-api'] -> Class['cinder::policy']
    Package['cinder-api'] -> Cinder_config<||>
    Package['cinder-api'] -> Cinder_api_paste_ini<||>
    Package['cinder-api'] -> Service['cinder-api']
    Package['cinder-api'] ~> Exec<| title == 'cinder-manage db_sync' |>
    package { 'cinder-api':
      ensure => $package_ensure,
      name   => $::cinder::params::api_package,
      tag    => 'openstack',
    }
  }

  if $sync_db {
    Cinder_config<||> ~> Exec['cinder-manage db_sync']

    exec { 'cinder-manage db_sync':
      command     => $::cinder::params::db_sync_command,
      path        => '/usr/bin',
      user        => 'cinder',
      refreshonly => true,
      logoutput   => 'on_failure',
      subscribe   => Package['cinder'],
      before      => Service['cinder-api'],
    }
  }

  if $enabled {
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
    hasstatus => true,
    require   => Package['cinder'],
  }

  cinder_config {
    'DEFAULT/osapi_volume_listen':  value => $bind_host;
    'DEFAULT/osapi_volume_workers': value => $service_workers;
  }

  if $os_region_name {
    cinder_config {
      'DEFAULT/os_region_name': value => $os_region_name;
    }
  }

  if $keystone_auth_uri and $auth_uri {
    fail('both keystone_auth_uri and auth_uri are set and they have the same meaning')
  }
  elsif !$keystone_auth_uri and !$auth_uri {
    warning('use of keystone_auth_protocol, keystone_auth_host, and service_port is deprecated, please set auth_uri directly')
    $auth_uri_real = "${keystone_auth_protocol}://${keystone_auth_host}:${service_port}/"
  }
  elsif $keystone_auth_uri {
    warning('keystone_auth_uri has been renamed to auth_uri')
    $auth_uri_real = $keystone_auth_uri
  }
  else {
    $auth_uri_real = $auth_uri
  }
  cinder_api_paste_ini { 'filter:authtoken/auth_uri': value => $auth_uri_real; }

  if $keystone_enabled {
    cinder_config {
      'DEFAULT/auth_strategy':     value => 'keystone' ;
    }

    cinder_api_paste_ini {
      'filter:authtoken/admin_tenant_name': value => $keystone_tenant;
      'filter:authtoken/admin_user':        value => $keystone_user;
      'filter:authtoken/admin_password':    value => $keystone_password, secret => true;
    }

    # if both auth_uri and identity_uri are set we skip these deprecated settings entirely
    if !$auth_uri or !$identity_uri {
      if $keystone_auth_host {
        warning('The keystone_auth_host parameter is deprecated. Please use auth_uri and identity_uri instead.')
        cinder_api_paste_ini {
          'filter:authtoken/service_host': value => $keystone_auth_host;
          'filter:authtoken/auth_host':    value => $keystone_auth_host;
        }
      } else {
        cinder_api_paste_ini {
          'filter:authtoken/service_host': ensure => absent;
          'filter:authtoken/auth_host':    ensure => absent;
        }
      }

      if $keystone_auth_protocol {
        warning('The keystone_auth_protocol parameter is deprecated. Please use auth_uri and identity_uri instead.')
        cinder_api_paste_ini {
          'filter:authtoken/service_protocol': value => $keystone_auth_protocol;
          'filter:authtoken/auth_protocol':    value => $keystone_auth_protocol;
        }
      } else {
        cinder_api_paste_ini {
          'filter:authtoken/service_protocol': ensure => absent;
          'filter:authtoken/auth_protocol':    ensure => absent;
        }
      }

      if $keystone_auth_port {
        warning('The keystone_auth_port parameter is deprecated. Please use auth_uri and identity_uri instead.')
        cinder_api_paste_ini {
          'filter:authtoken/auth_port':    value => $keystone_auth_port;
        }
      } else {
        cinder_api_paste_ini {
          'filter:authtoken/auth_port':    ensure => absent;
        }
      }

      if $service_port {
        warning('The service_port parameter is deprecated. Please use auth_uri and identity_uri instead.')
        cinder_api_paste_ini {
          'filter:authtoken/service_port': value => $service_port;
        }
      } else {
        cinder_api_paste_ini {
          'filter:authtoken/service_port': ensure => absent;
        }
      }


      if $keystone_auth_admin_prefix {
        warning('The keystone_auth_admin_prefix parameter is deprecated. Please use auth_uri and identity_uri instead.')
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
    else {
      cinder_api_paste_ini {
        'filter:authtoken/auth_admin_prefix': ensure => absent;
      }
      cinder_api_paste_ini {
        'filter:authtoken/service_port':     ensure => absent;
        'filter:authtoken/auth_port':        ensure => absent;
        'filter:authtoken/service_host':     ensure => absent;
        'filter:authtoken/auth_host':        ensure => absent;
        'filter:authtoken/service_protocol': ensure => absent;
        'filter:authtoken/auth_protocol':    ensure => absent;
      }
    }

    if $identity_uri {
      cinder_api_paste_ini {
        'filter:authtoken/identity_uri': value => $identity_uri;
      }
    } else {
      cinder_api_paste_ini {
        'filter:authtoken/identity_uri': ensure => absent;
      }
    }
  }

  if ($ratelimits != undef) {
    cinder_api_paste_ini {
      'filter:ratelimit/paste.filter_factory': value => $ratelimits_factory;
      'filter:ratelimit/limits':               value => $ratelimits;
    }
  }

  if $default_volume_type {
    cinder_config {
      'DEFAULT/default_volume_type': value => $default_volume_type;
    }
  } else {
    cinder_config {
      'DEFAULT/default_volume_type': ensure => absent;
    }
  }

  if $validate {
    $defaults = {
      'cinder-api' => {
        'command'  => "cinder --os-auth-url ${auth_uri_real} --os-tenant-name ${keystone_tenant} --os-username ${keystone_user} --os-password ${keystone_password} list",
      }
    }
    $validation_options_hash = merge ($defaults, $validation_options)
    create_resources('openstacklib::service_validation', $validation_options_hash, {'subscribe' => 'Service[cinder-api]'})
  }

}
