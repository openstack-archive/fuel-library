# == Class: cinder::keystone::auth
#
# Configures Cinder user, service and endpoint in Keystone.
#
# === Parameters
#
# [*password*]
#   Password for Cinder user. Required.
#
# [*email*]
#   Email for Cinder user. Optional. Defaults to 'cinder@localhost'.
#
# [*auth_name*]
#   Username for Cinder service. Optional. Defaults to 'cinder'.
#
# [*configure_endpoint*]
#   Should Cinder endpoint be configured? Optional. Defaults to 'true'.
#
# [*service_type*]
#    Type of service. Optional. Defaults to 'volume'.
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
#    Port for endpoint. Optional. Defaults to '8776'.
#
# [*region*]
#    Region for endpoint. Optional. Defaults to 'RegionOne'.
#
# [*tenant*]
#    Tenant for Cinder user. Optional. Defaults to 'services'.
#
# [*public_protocol*]
#    Protocol for public endpoint. Optional. Defaults to 'http'.
#
# [*internal_protocol*]
#    Protocol for internal endpoint. Optional. Defaults to 'http'.
#
# [*admin_protocol*]
#    Protocol for admin endpoint. Optional. Defaults to 'http'.
#
class cinder::keystone::auth (
  $password,
  $auth_name          = 'cinder',
  $email              = 'cinder@localhost',
  $tenant             = 'services',
  $configure_endpoint = true,
  $service_type       = 'volume',
  $public_address     = '127.0.0.1',
  $admin_address      = '127.0.0.1',
  $internal_address   = '127.0.0.1',
  $port               = '8776',
  $volume_version     = 'v1',
  $region             = 'RegionOne',
  $public_protocol    = 'http',
  $admin_protocol     = 'http',
  $internal_protocol  = 'http'
) {

  Keystone_user_role["${auth_name}@${tenant}"] ~> Service <| name == 'cinder-api' |>

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
    email    => $email,
    tenant   => $tenant,
  }
  keystone_user_role { "${auth_name}@${tenant}":
    ensure  => present,
    roles   => 'admin',
  }
  keystone_service { $auth_name:
    ensure      => present,
    type        => $service_type,
    description => 'Cinder Service',
  }

  if $configure_endpoint {
    keystone_endpoint { "${region}/${auth_name}":
      ensure       => present,
      public_url   => "${public_protocol}://${public_address}:${port}/${volume_version}/%(tenant_id)s",
      admin_url    => "${admin_protocol}://${admin_address}:${port}/${volume_version}/%(tenant_id)s",
      internal_url => "${internal_protocol}://${internal_address}:${port}/${volume_version}/%(tenant_id)s",
    }
  }
}
