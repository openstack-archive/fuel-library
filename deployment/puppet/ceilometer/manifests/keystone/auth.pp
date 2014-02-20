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
#    Port for endpoint. Optional. Defaults to '8777'.
#
# [*region*]
#    Region for endpoint. Optional. Defaults to 'RegionOne'.
#
# [*tenant*]
#    Tenant for Ceilometer user. Optional. Defaults to 'services'.
#
# [*protocol*]
#    Protocol for public endpoint. Optional. Defaults to 'http'.
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
  $api_protocol       = 'http',
  # $public_protocol    = $api_protocol,
  # $admin_protocol     = $api_protocol,
  # $internal_protocol  = $api_protocol,
  $configure_endpoint = true
) {

  validate_string($password)

  Keystone_user_role["${auth_name}@${tenant}"] ~>
    Service <| title == 'ceilometer-api' |>

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
    $public_protocol    = $api_protocol
    $admin_protocol     = $api_protocol
    $internal_protocol  = $api_protocol

    keystone_endpoint { "${auth_name}":
      region       => $region,
      ensure       => present,
      public_url   => "${public_protocol}://${public_address}:${port}",
      admin_url    => "${admin_protocol}://${admin_address}:${port}",
      internal_url => "${internal_protocol}://${internal_address}:${port}",
    }
  }
}

