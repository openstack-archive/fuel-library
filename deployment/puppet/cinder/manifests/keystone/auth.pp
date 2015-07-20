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
# [*region*]
#    Region for endpoint. Optional. Defaults to 'RegionOne'.
#
# [*tenant*]
#    Tenant for Cinder user. Optional. Defaults to 'services'.
#
# [*public_url*]
#   (optional) The endpoint's public url. (Defaults to 'http://127.0.0.1:8776/v1/%(tenant_id)s')
#   This url should *not* contain any trailing '/'.
#
# [*internal_url*]
#   (optional) The endpoint's internal url. (Defaults to 'http://127.0.0.1:8776/v1/%(tenant_id)s')
#   This url should *not* contain any trailing '/'.
#
# [*admin_url*]
#   (optional) The endpoint's admin url. (Defaults to 'http://127.0.0.1:8776/v1/%(tenant_id)s')
#   This url should *not* contain any trailing '/'.
#
# [*public_url_v2*]
#   (optional) The v2 endpoint's public url. (Defaults to 'http://127.0.0.1:8776/v2/%(tenant_id)s')
#   This url should *not* contain any trailing '/'.
#
# [*internal_url_v2*]
#   (optional) The v2 endpoint's internal url. (Defaults to 'http://127.0.0.1:8776/v2/%(tenant_id)s')
#   This url should *not* contain any trailing '/'.
#
# [*admin_url_v2*]
#   (optional) The v2 endpoint's admin url. (Defaults to 'http://127.0.0.1:8776/v2/%(tenant_id)s')
#   This url should *not* contain any trailing '/'.
#
# [*volume_version*]
#   (optional) DEPRECATED: Use public_url, internal_url and admin_url instead.
#   Cinder API version. (Defaults to 'v1')
#   Setting this parameter overrides public_url, internal_url and admin_url parameters.
#
# [*port*]
#   (optional) DEPRECATED: Use public_url, internal_url and admin_url instead.
#   Port for endpoint. (Defaults to 8776)
#   Setting this parameter overrides public_url, internal_url and admin_url parameters.
#
# [*public_protocol*]
#   (optional) DEPRECATED: Use public_url instead.
#   Protocol for public endpoint. (Defaults to 'http')
#   Setting this parameter overrides public_url parameter.
#
# [*internal_protocol*]
#   (optional) DEPRECATED: Use internal_url and internal_url_v2 instead.
#   Protocol for internal endpoint. (Defaults to 'http')
#   Setting this parameter overrides internal_url and internal_url_v2 parameter.
#
# [*admin_protocol*]
#   (optional) DEPRECATED: Use admin_url and admin_url_v2 instead.
#   Protocol for admin endpoint. (Defaults to 'http')
#   Setting this parameter overrides admin_url and admin_url_v2 parameter.
#
# [*public_address*]
#   (optional) DEPRECATED: Use public_url instead.
#   Public address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides public_url and public_url_v2 parameter.
#
# [*internal_address*]
#   (optional) DEPRECATED: Use internal_url instead.
#   Internal address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides internal_url and internal_url_v2 parameter.
#
# [*admin_address*]
#   (optional) DEPRECATED: Use admin_url instead.
#   Admin address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides admin_url and admin_url_v2 parameter.
#
# === Deprecation notes
#
# If any value is provided for public_protocol, public_address or public_port parameters,
# public_url will be completely ignored. The same applies for internal and admin parameters.
#
# === Examples
#
#  class { 'cinder::keystone::auth':
#    public_url   => 'https://10.0.0.10:8776/v1/%(tenant_id)s',
#    internal_url => 'https://10.0.0.20:8776/v1/%(tenant_id)s',
#    admin_url    => 'https://10.0.0.30:8776/v1/%(tenant_id)s',
#  }
#
class cinder::keystone::auth (
  $password,
  $auth_name             = 'cinder',
  $auth_name_v2          = 'cinderv2',
  $tenant                = 'services',
  $email                 = 'cinder@localhost',
  $public_url            = 'http://127.0.0.1:8776/v1/%(tenant_id)s',
  $internal_url          = 'http://127.0.0.1:8776/v1/%(tenant_id)s',
  $admin_url             = 'http://127.0.0.1:8776/v1/%(tenant_id)s',
  $public_url_v2         = 'http://127.0.0.1:8776/v2/%(tenant_id)s',
  $internal_url_v2       = 'http://127.0.0.1:8776/v2/%(tenant_id)s',
  $admin_url_v2          = 'http://127.0.0.1:8776/v2/%(tenant_id)s',
  $configure_endpoint    = true,
  $configure_endpoint_v2 = true,
  $configure_user        = true,
  $configure_user_role   = true,
  $service_name          = undef,
  $service_name_v2       = undef,
  $service_type          = 'volume',
  $service_type_v2       = 'volumev2',
  $region                = 'RegionOne',
  # DEPRECATED PARAMETERS
  $port                  = undef,
  $volume_version        = undef,
  $public_address        = undef,
  $admin_address         = undef,
  $internal_address      = undef,
  $public_protocol       = undef,
  $admin_protocol        = undef,
  $internal_protocol     = undef
) {

  if $volume_version {
    warning('The volume_version parameter is deprecated, use public_url, internal_url and admin_url instead.')
  }

  if $port {
    warning('The port parameter is deprecated, use public_url, internal_url and admin_url instead.')
  }

  if $public_protocol {
    warning('The public_protocol parameter is deprecated, use public_url instead.')
  }

  if $internal_protocol {
    warning('The internal_protocol parameter is deprecated, use internal_url instead.')
  }

  if $admin_protocol {
    warning('The admin_protocol parameter is deprecated, use admin_url instead.')
  }

  if $public_address {
    warning('The public_address parameter is deprecated, use public_url instead.')
  }

  if $internal_address {
    warning('The internal_address parameter is deprecated, use internal_url instead.')
  }

  if $admin_address {
    warning('The admin_address parameter is deprecated, use admin_url instead.')
  }

  $real_service_name = pick($service_name, $auth_name)
  $real_service_name_v2 = pick($service_name_v2, $auth_name_v2)

  if $real_service_name == $real_service_name_v2 {
    fail('cinder::keystone::auth parameters service_name and service_name_v2 must be different.')
  }

  if ($public_protocol or $public_address or $port or $volume_version) {
    $public_url_real = sprintf('%s://%s:%s/%s/%%(tenant_id)s',
      pick($public_protocol, 'http'),
      pick($public_address, '127.0.0.1'),
      pick($port, '8776'),
      pick($volume_version, 'v1'))
  } else {
    $public_url_real = $public_url
  }

  if ($internal_protocol or $internal_address or $port or $volume_version) {
    $internal_url_real = sprintf('%s://%s:%s/%s/%%(tenant_id)s',
      pick($internal_protocol, 'http'),
      pick($internal_address, '127.0.0.1'),
      pick($port, '8776'),
      pick($volume_version, 'v1'))
  } else {
    $internal_url_real = $internal_url
  }

  if ($admin_protocol or $admin_address or $port or $volume_version) {
    $admin_url_real = sprintf('%s://%s:%s/%s/%%(tenant_id)s',
      pick($admin_protocol, 'http'),
      pick($admin_address, '127.0.0.1'),
      pick($port, '8776'),
      pick($volume_version, 'v1'))
  } else {
    $admin_url_real = $admin_url
  }

  if ($public_protocol or $public_address or $port) {
    $public_url_v2_real = sprintf('%s://%s:%s/v2/%%(tenant_id)s',
      pick($public_protocol, 'http'),
      pick($public_address, '127.0.0.1'),
      pick($port, '8776'))
  } else {
    $public_url_v2_real = $public_url_v2
  }

  if ($internal_protocol or $internal_address or $port) {
    $internal_url_v2_real = sprintf('%s://%s:%s/v2/%%(tenant_id)s',
      pick($internal_protocol, 'http'),
      pick($internal_address, '127.0.0.1'),
      pick($port, '8776'))
  } else {
    $internal_url_v2_real = $internal_url_v2
  }

  if ($admin_protocol or $admin_address or $port) {
    $admin_url_v2_real = sprintf('%s://%s:%s/v2/%%(tenant_id)s',
      pick($admin_protocol, 'http'),
      pick($admin_address, '127.0.0.1'),
      pick($port, '8776'))
  } else {
    $admin_url_v2_real = $admin_url_v2
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
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
  }

  keystone::resource::service_identity { 'cinderv2':
    configure_user      => false,
    configure_user_role => false,
    configure_endpoint  => $configure_endpoint_v2,
    service_type        => $service_type_v2,
    service_description => 'Cinder Service v2',
    service_name        => $real_service_name_v2,
    region              => $region,
    public_url          => $public_url_v2_real,
    admin_url           => $admin_url_v2_real,
    internal_url        => $internal_url_v2_real,
  }

  if $configure_user_role {
    Keystone_user_role["${auth_name}@${tenant}"] ~> Service <| name == 'cinder-api' |>
  }

}
