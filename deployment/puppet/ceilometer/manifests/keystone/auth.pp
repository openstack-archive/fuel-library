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
# [*configure_user*]
#   Should Ceilometer service user be configured? Optional. Defaults to 'true'.
#
# [*configure_user_role*]
#   Should roles be configured on Ceilometer service user? Optional. Defaults to 'true'.
#
# [*service_name*]
#   Name of the service. Optional. Defaults to value of auth_name.
#
# [*service_type*]
#    Type of service. Optional. Defaults to 'metering'.
#
# [*region*]
#    Region for endpoint. Optional. Defaults to 'RegionOne'.
#
# [*tenant*]
#    Tenant for Ceilometer user. Optional. Defaults to 'services'.
#
# [*public_url*]
#   (optional) The endpoint's public url. (Defaults to 'http://127.0.0.1:8777')
#   This url should *not* contain any trailing '/'.
#
# [*admin_url*]
#   (optional) The endpoint's admin url. (Defaults to 'http://127.0.0.1:8777')
#   This url should *not* contain any trailing '/'.
#
# [*internal_url*]
#   (optional) The endpoint's internal url. (Defaults to 'http://127.0.0.1:8777')
#   This url should *not* contain any trailing '/'.
#
# [*port*]
#   (optional) DEPRECATED: Use public_url, internal_url and admin_url instead.
#   Default port for endpoints. (Defaults to 8777)
#   Setting this parameter overrides public_url, internal_url and admin_url parameters.
#
# [*public_protocol*]
#   (optional) DEPRECATED: Use public_url instead.
#   Protocol for public endpoint. (Defaults to 'http')
#   Setting this parameter overrides public_url parameter.
#
# [*public_address*]
#   (optional) DEPRECATED: Use public_url instead.
#   Public address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides public_url parameter.
#
# [*internal_protocol*]
#   (optional) DEPRECATED: Use internal_url instead.
#   Protocol for internal endpoint. (Defaults to 'http')
#   Setting this parameter overrides internal_url parameter.
#
# [*internal_address*]
#   (optional) DEPRECATED: Use internal_url instead.
#   Internal address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides internal_url parameter.
#
# [*admin_protocol*]
#   (optional) DEPRECATED: Use admin_url instead.
#   Protocol for admin endpoint. (Defaults to 'http')
#   Setting this parameter overrides admin_url parameter.
#
# [*admin_address*]
#   (optional) DEPRECATED: Use admin_url instead.
#   Admin address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides admin_url parameter.
#
# === Deprecation notes
#
# If any value is provided for public_protocol, public_address or port parameters,
# public_url will be completely ignored. The same applies for internal and admin parameters.
#
# === Examples
#
#  class { 'ceilometer::keystone::auth':
#    public_url   => 'https://10.0.0.10:8777',
#    internal_url => 'https://10.0.0.11:8777',
#    admin_url    => 'https://10.0.0.11:8777',
#  }
#
class ceilometer::keystone::auth (
  $password             = false,
  $email                = 'ceilometer@localhost',
  $auth_name            = 'ceilometer',
  $configure_user       = true,
  $configure_user_role  = true,
  $service_name         = undef,
  $service_type         = 'metering',
  $region               = 'RegionOne',
  $tenant               = 'services',
  $configure_endpoint   = true,
  $public_url           = 'http://127.0.0.1:8777',
  $admin_url            = 'http://127.0.0.1:8777',
  $internal_url         = 'http://127.0.0.1:8777',
  # DEPRECATED PARAMETERS
  $port                 = undef,
  $public_protocol      = undef,
  $public_address       = undef,
  $internal_protocol    = undef,
  $internal_address     = undef,
  $admin_protocol       = undef,
  $admin_address        = undef,
) {

  validate_string($password)

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

  $service_name_real = pick($service_name, $auth_name)

  if ($public_protocol or $public_address or $port) {
    $public_url_real = sprintf('%s://%s:%s',
      pick($public_protocol, 'http'),
      pick($public_address, '127.0.0.1'),
      pick($port, '8777'))
  } else {
    $public_url_real = $public_url
  }

  if ($admin_protocol or $admin_address or $port) {
    $admin_url_real = sprintf('%s://%s:%s',
      pick($admin_protocol, 'http'),
      pick($admin_address, '127.0.0.1'),
      pick($port, '8777'))
  } else {
    $admin_url_real = $admin_url
  }

  if ($internal_protocol or $internal_address or $port) {
    $internal_url_real = sprintf('%s://%s:%s',
      pick($internal_protocol, 'http'),
      pick($internal_address, '127.0.0.1'),
      pick($port, '8777'))
  } else {
    $internal_url_real = $internal_url
  }

  ::keystone::resource::service_identity { $auth_name:
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => $service_type,
    service_description => 'Openstack Metering Service',
    service_name        => $service_name_real,
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    roles               => ['admin', 'ResellerAdmin'],
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
  }

  if $configure_user_role {
    if !defined(Keystone_role['ResellerAdmin']) {
      keystone_role { 'ResellerAdmin':
        ensure => present,
      }
    }
    Keystone_role['ResellerAdmin'] -> Keystone_user_role["${auth_name}@${tenant}"] ~>
      Service <| name == 'ceilometer-api' |>
  }

}

