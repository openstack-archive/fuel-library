# == Class: ceilometer::keystone::auth
#
# Configures Ceilometer user, service and endpoint in Keystone.
#
# === Parameters
#
# [*password*]
#   Password for Ceilometer user. Required.
#
# [*email*]
#   Email for Ceilometer user. Optional. Defaults to 'ceilometer@localhost'.
#
# [*auth_name*]
#   Username for Ceilometer service. Optional. Defaults to 'ceilometer'.
#
# [*configure_endpoint*]
#   Should Ceilometer endpoint be configured? Optional. Defaults to 'true'.
#
# [*service_type*]
#    Type of service. Optional. Defaults to 'metering'.
#
# [*public_address*]
#    Public address for endpoint. Optional. Defaults to '127.0.0.1'.
#
# [*admin_address*]
#    Admin address for endpoint. Optional. Defaults to '127.0.0.1'.
#
# [*internal_address*]
#    Internal address for endpoint. Optional. Defaults to '127.0.0.1'.
#
# [*port*]
#    Default port for enpoints. Optional. Defaults to '8777'.
#
# [*region*]
#    Region for endpoint. Optional. Defaults to 'RegionOne'.
#
# [*tenant*]
#    Tenant for Ceilometer user. Optional. Defaults to 'services'.
#
# [*public_protocol*]
#    Protocol for public endpoint. Optional. Defaults to 'http'.
#
# [*admin_protocol*]
#    Protocol for admin endpoint. Optional. Defaults to 'http'.
#
# [*internal_protocol*]
#    Protocol for public endpoint. Optional. Defaults to 'http'.
#
# [*public_url*]
#    The endpoint's public url.
#    Optional. Defaults to $public_protocol://$public_address:$port
#    This url should *not* contain any API version and should have
#    no trailing '/'
#    Setting this variable overrides other $public_* parameters.
#
# [*admin_url*]
#    The endpoint's admin url.
#    Optional. Defaults to $admin_protocol://$admin_address:$port
#    This url should *not* contain any API version and should have
#    no trailing '/'
#    Setting this variable overrides other $admin_* parameters.
#
# [*internal_url*]
#    The endpoint's internal url.
#    Optional. Defaults to $internal_protocol://$internal_address:$port
#    This url should *not* contain any API version and should have
#    no trailing '/'
#    Setting this variable overrides other $internal_* parameters.
#
class ceilometer::keystone::auth (
  $password           = false,
  $email              = 'ceilometer@localhost',
  $auth_name          = 'ceilometer',
  $service_type       = 'metering',
  $public_address     = '127.0.0.1',
  $admin_address      = '127.0.0.1',
  $internal_address   = '127.0.0.1',
  $port               = '8777',
  $region             = 'RegionOne',
  $tenant             = 'services',
  $public_protocol    = 'http',
  $admin_protocol     = 'http',
  $internal_protocol  = 'http',
  $configure_endpoint = true,
  $public_url         = undef,
  $admin_url          = undef,
  $internal_url       = undef,
) {

  validate_string($password)

  if $public_url {
    $public_url_real = $public_url
  } else {
    $public_url_real = "${public_protocol}://${public_address}:${port}"
  }

  if $admin_url {
    $admin_url_real = $admin_url
  } else {
    $admin_url_real = "${admin_protocol}://${admin_address}:${port}"
  }

  if $internal_url {
    $internal_url_real = $internal_url
  } else {
    $internal_url_real = "${internal_protocol}://${internal_address}:${port}"
  }

  Keystone_user_role["${auth_name}@${tenant}"] ~>
    Service <| name == 'ceilometer-api' |>

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
    email    => $email,
    tenant   => $tenant,
  }
  if !defined(Keystone_role['ResellerAdmin']) {
    keystone_role { 'ResellerAdmin':
      ensure => present,
    }
  }
  keystone_user_role { "${auth_name}@${tenant}":
    ensure  => present,
    roles   => ['admin', 'ResellerAdmin'],
    require => Keystone_role['ResellerAdmin'],
  }
  keystone_service { $auth_name:
    ensure      => present,
    type        => $service_type,
    description => 'Openstack Metering Service',
  }
  if $configure_endpoint {
    keystone_endpoint { "${region}/${auth_name}":
      ensure       => present,
      public_url   => $public_url_real,
      admin_url    => $admin_url_real,
      internal_url => $internal_url_real,
    }
  }
}

