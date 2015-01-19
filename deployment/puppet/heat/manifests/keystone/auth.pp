# == Class: heat::heat::auth
#
# Configures heat user, service and endpoint in Keystone.
#
# === Parameters
#
# [*password*]
#   Password for heat user. Required.
#
# [*email*]
#   Email for heat user. Optional. Defaults to 'heat@localhost'.
#
# [*auth_name*]
#   Username for heat service. Optional. Defaults to 'heat'.
#
# [*configure_endpoint*]
#   Should heat endpoint be configured? Optional. Defaults to 'true'.
#
# [*service_name*]
#   Servicename for heat service. Optional. Defaults to 'heat'.
#
# [*service_type*]
#    Type of service. Optional. Defaults to 'orchestration'.
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
# [*version*]
#   Version of API to use.  Optional.  Defaults to 'v1'
#
# [*port*]
#    Port for endpoint. Optional. Defaults to '8004'.
#
# [*region*]
#    Region for endpoint. Optional. Defaults to 'RegionOne'.
#
# [*tenant*]
#    Tenant for heat user. Optional. Defaults to 'services'.
#
# [*protocol*]
#    Protocol for public endpoint. Optional. Defaults to 'http'.
#
# [allow_add_user] Allow create user in authentication server. Optional. Defaults to true.
#
class heat::keystone::auth (
  $password           = false,
  $email              = 'heat@localhost',
  $auth_name          = 'heat',
  $service_name       = 'heat',
  $service_type       = 'orchestration',
  $public_address     = '127.0.0.1',
  $admin_address      = '127.0.0.1',
  $internal_address   = '127.0.0.1',
  $port               = '8004',
  $version            = 'v1',
  $region             = 'RegionOne',
  $tenant             = 'services',
  $public_protocol    = 'http',
  $admin_protocol     = 'http',
  $internal_protocol  = 'http',
  $configure_endpoint = true,
  $allow_add_user     = true,
) {

  validate_string($password)

  Keystone_user_role["${auth_name}@${tenant}"] ~>
    Service <| name == 'heat-api' |>

  if ($allow_add_user != false) {
    keystone_user { $auth_name:
      ensure   => present,
      password => $password,
      email    => $email,
      tenant   => $tenant,
    }
  }

  if !defined(Keystone_user_role["${auth_name}@${tenant}"]) {
    keystone_user_role { "${auth_name}@${tenant}":
      ensure  => present,
      roles   => ['admin'],
    }
  }

  keystone_role { 'heat_stack_user':
        ensure => present,
  }

  keystone_service { $service_name:
    ensure      => present,
    type        => $service_type,
    description => 'Openstack Orchestration Service',
  }
  if $configure_endpoint {
    keystone_endpoint { "${region}/${service_name}":
      ensure       => present,
      public_url   => "${public_protocol}://${public_address}:${port}/${version}/%(tenant_id)s",
      admin_url    => "${admin_protocol}://${admin_address}:${port}/${version}/%(tenant_id)s",
      internal_url => "${internal_protocol}://${internal_address}:${port}/${version}/%(tenant_id)s",
    }
  }
}

