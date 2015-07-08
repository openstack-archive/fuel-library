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
# [*auth_name_v2*]
#   Username for Cinder v2 service. Optional. Defaults to 'cinderv2'.
#
# [*configure_endpoint*]
#   Should Cinder endpoint be configured? Optional. Defaults to 'true'.
#   API v1 endpoint should be enabled in Icehouse for compatibility with Nova.
#
# [*configure_endpoint_v2*]
#   Should Cinder v2 endpoint be configured? Optional. Defaults to 'true'.
#
# [*configure_user*]
#   Should the service user be configured? Optional. Defaults to 'true'.
#
# [*configure_user_role*]
#   Should the admin role be configured for the service user?
#   Optional. Defaults to 'true'.
#
# [*service_name*]
#   (optional) Name of the service.
#   Defaults to the value of auth_name, but must differ from the value
#   of service_name_v2.
#
# [*service_name_v2*]
#   (optional) Name of the v2 service.
#   Defaults to the value of auth_name_v2, but must differ from the value
#   of service_name.
#
# [*service_type*]
#    Type of service. Optional. Defaults to 'volume'.
#
# [*service_type_v2*]
#    Type of API v2 service. Optional. Defaults to 'volume2'.
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
# [*volume_version*]
#    Cinder API version. Optional. Defaults to 'v1'.
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
  $auth_name             = 'cinder',
  $auth_name_v2          = 'cinderv2',
  $email                 = 'cinder@localhost',
  $tenant                = 'services',
  $configure_endpoint    = true,
  $configure_endpoint_v2 = true,
  $configure_user        = true,
  $configure_user_role   = true,
  $service_name          = undef,
  $service_name_v2       = undef,
  $service_type          = 'volume',
  $service_type_v2       = 'volumev2',
  $public_address        = '127.0.0.1',
  $admin_address         = '127.0.0.1',
  $internal_address      = '127.0.0.1',
  $port                  = '8776',
  $volume_version        = 'v1',
  $region                = 'RegionOne',
  $public_protocol       = 'http',
  $admin_protocol        = 'http',
  $internal_protocol     = 'http'
) {
  if $service_name {
    $real_service_name = $service_name
  } else {
    $real_service_name = $auth_name
  }
  if $service_name_v2 {
    $real_service_name_v2 = $service_name_v2
  } else {
    $real_service_name_v2 = $auth_name_v2
  }

  if $real_service_name == $real_service_name_v2 {
    fail('cinder::keystone::auth parameters service_name and service_name_v2 must be different.')
  }
  keystone::resource::service_identity { 'cinder':
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => $service_type,
    service_description => 'Cinder Service',
    service_name        => $real_service_name,
    region              => $region,
    auth_name           => $auth_name,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => "${public_protocol}://${public_address}:${port}/${volume_version}/%(tenant_id)s",
    admin_url           => "${admin_protocol}://${admin_address}:${port}/${volume_version}/%(tenant_id)s",
    internal_url        => "${internal_protocol}://${internal_address}:${port}/${volume_version}/%(tenant_id)s",
  }

  keystone::resource::service_identity { 'cinderv2':
    configure_user      => false,
    configure_user_role => false,
    configure_endpoint  => $configure_endpoint_v2,
    service_type        => $service_type_v2,
    service_description => 'Cinder Service v2',
    service_name        => $real_service_name_v2,
    region              => $region,
    public_url          => "${public_protocol}://${public_address}:${port}/v2/%(tenant_id)s",
    admin_url           => "${admin_protocol}://${admin_address}:${port}/v2/%(tenant_id)s",
    internal_url        => "${internal_protocol}://${internal_address}:${port}/v2/%(tenant_id)s",
  }

  if $configure_user_role {
    Keystone_user_role["${auth_name}@${tenant}"] ~> Service <| name == 'cinder-api' |>
  }

}
