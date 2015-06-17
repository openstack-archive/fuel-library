# == Class: heat::keystone::auth_cfn
#
# Configures heat-api-cfn user, service and endpoint in Keystone.
#
# === Parameters
# [*password*]
#   (Mandatory) Password for heat-cfn user.
#
# [*email*]
#   (Optional) Email for heat-cfn user.
#   Defaults to 'heat@localhost'.
#
# [*auth_name*]
#   (Optional) Username for heat-cfn service.
#   Defaults to 'heat'.
#
# [*configure_endpoint*]
#   (Optional) Should heat-cfn endpoint be configured?
#   Defaults to 'true'.
#
# [*configure_user*]
#   (Optional) Whether to create the service user.
#   Defaults to 'true'.
#
# [*configure_user_role*]
#   (Optional) Whether to configure the admin role for the service user.
#   Defaults to 'true'.
#
# [*service_name*]
#   (Optional) Name of the service.
#   Defaults to the value of auth_name.
#
# [*service_type*]
#   (Optional) Type of service.
#   Defaults to 'cloudformation'.
#
# [*public_address*]
#   (Optional) Public address for endpoint.
#   Defaults to '127.0.0.1'.
#
# [*admin_address*]
#   (Optional) Admin address for endpoint.
#   Defaults to '127.0.0.1'.
#
# [*internal_address*]
#   (Optional) Internal address for endpoint.
#   Defaults to '127.0.0.1'.
#
# [*port*]
#   (Optional) Port for endpoint.
#   Defaults to '8000'.
#
# [*version*]
#   (Optional) Version for API.
#   Defaults to 'v1'

# [*region*]
#   (Optional) Region for endpoint.
#   Defaults to 'RegionOne'.
#
# [*tenant*]
#   (Optional) Tenant for heat-cfn user.
#   Defaults to 'services'.
#
# [*public_protocol*]
#   (Optional) Protocol for public endpoint.
#   Defaults to 'http'.
#
# [*admin_protocol*]
#   (Optional) Protocol for admin endpoint.
#   Defaults to 'http'.
#
# [*internal_protocol*]
#   (Optional) Protocol for internal endpoint.
#   Defaults to 'http'.
#
class heat::keystone::auth_cfn (
  $password             = false,
  $email                = 'heat-cfn@localhost',
  $auth_name            = 'heat-cfn',
  $service_name         = undef,
  $service_type         = 'cloudformation',
  $public_address       = '127.0.0.1',
  $admin_address        = '127.0.0.1',
  $internal_address     = '127.0.0.1',
  $port                 = '8000',
  $version              = 'v1',
  $region               = 'RegionOne',
  $tenant               = 'services',
  $public_protocol      = 'http',
  $admin_protocol       = 'http',
  $internal_protocol    = 'http',
  $configure_endpoint   = true,
  $configure_user       = true,
  $configure_user_role  = true,
) {

  validate_string($password)

  if $service_name == undef {
    $real_service_name = $auth_name
  } else {
    $real_service_name = $service_name
  }

  if $configure_user {
    keystone_user { $auth_name:
      ensure   => present,
      password => $password,
      email    => $email,
      tenant   => $tenant,
    }
  }

  if $configure_user_role {
    Keystone_user_role["${auth_name}@${tenant}"] ~>
      Service <| name == 'heat-api-cfn' |>

    keystone_user_role { "${auth_name}@${tenant}":
      ensure => present,
      roles  => ['admin'],
    }
  }

  keystone_service { $real_service_name:
    ensure      => present,
    type        => $service_type,
    description => 'Openstack Cloudformation Service',
  }
  if $configure_endpoint {
    keystone_endpoint { "${region}/${real_service_name}":
      ensure       => present,
      public_url   => "${public_protocol}://${public_address}:${port}/${version}/",
      admin_url    => "${admin_protocol}://${admin_address}:${port}/${version}/",
      internal_url => "${internal_protocol}://${internal_address}:${port}/${version}/",
    }
  }
}
