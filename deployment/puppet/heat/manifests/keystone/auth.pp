# == Class: heat::keystone::auth
#
# Configures heat user, service and endpoint in Keystone.
#
# === Parameters
# [*password*]
#   (Required) Password for heat user.
#
# [*email*]
#   (Optional) Email for heat user.
#   Defaults to 'heat@localhost'.
#
# [*auth_name*]
#   (Optional) Username for heat service.
#   Defaults to 'heat'.
#
# [*configure_endpoint*]
#   (Optional) Should heat endpoint be configured?
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
#   Defaults to 'orchestration'.
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
# [*version*]
#   (Optional) Version of API to use.
#   Defaults to 'v1'
#
# [*port*]
#   (Optional) Port for endpoint.
#   Defaults to '8004'.
#
# [*region*]
#   (Optional) Region for endpoint.
#   Defaults to 'RegionOne'.
#
# [*tenant*]
#   (Optional) Tenant for heat user.
#   Defaults to 'services'.
#
# [*protocol*]
#   (Optional) Protocol for public endpoint.
#   Defaults to 'http'.
#
# [*public_protocol*]
#   (Optional) Protocol for public endpoint.
#   Defaults to 'http'.
#
# [*admin_protocol*]
#   (Optional) Protocol for admin endpoint
#   Defaults to 'http'.
#
# [*internal_protocol*]
#   (Optional) Protocol for internal endpoint
#   Defaults to 'http'
#
# [*trusts_delegated_roles*]
#    (optional) Array of trustor roles to be delegated to heat.
#    Defaults to ['heat_stack_owner']
#
# [*configure_delegated_roles*]
#    (optional) Whether to configure the delegated roles.
#    Defaults to false until the deprecated parameters in heat::engine
#    are removed after Kilo.
#
class heat::keystone::auth (
  $password             = false,
  $email                = 'heat@localhost',
  $auth_name            = 'heat',
  $service_name         = undef,
  $service_type         = 'orchestration',
  $public_address       = '127.0.0.1',
  $admin_address        = '127.0.0.1',
  $internal_address     = '127.0.0.1',
  $port                 = '8004',
  $version              = 'v1',
  $region               = 'RegionOne',
  $tenant               = 'services',
  $public_protocol      = 'http',
  $admin_protocol       = 'http',
  $internal_protocol    = 'http',
  $configure_endpoint   = true,
  $configure_user       = true,
  $configure_user_role  = true,
  $trusts_delegated_roles    = ['heat_stack_owner'],
  $configure_delegated_roles = false,
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
      Service <| name == 'heat-api' |>

    keystone_user_role { "${auth_name}@${tenant}":
      ensure => present,
      roles  => ['admin'],
    }
  }

  keystone_role { 'heat_stack_user':
        ensure => present,
  }

  keystone_service { $real_service_name:
    ensure      => present,
    type        => $service_type,
    description => 'Openstack Orchestration Service',
  }
  if $configure_endpoint {
    keystone_endpoint { "${region}/${real_service_name}":
      ensure       => present,
      public_url   => "${public_protocol}://${public_address}:${port}/${version}/%(tenant_id)s",
      admin_url    => "${admin_protocol}://${admin_address}:${port}/${version}/%(tenant_id)s",
      internal_url => "${internal_protocol}://${internal_address}:${port}/${version}/%(tenant_id)s",
    }
  }

  if $configure_delegated_roles {
    # Sanity check - remove after we remove the deprecated item
    if $heat::engine::configure_delegated_roles {
      fail('both heat::engine and heat::keystone::auth are both trying to configure delegated roles')
    }
    # if this is a keystone only node, we configure the role here
    # but let engine.pp set the config file. A keystone only node
    # will not have a heat.conf file. We will use the value in
    # engine.pp as the one source of truth for the delegated role list.
    keystone_role { $trusts_delegated_roles:
      ensure => present,
    }
  }
}
