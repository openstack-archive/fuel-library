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
# [*configure_service*]
#   (Optional) Should heat-cfn service be configured?
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

# [*region*]
#   (Optional) Region for endpoint.
#   Defaults to 'RegionOne'.
#
# [*tenant*]
#   (Optional) Tenant for heat-cfn user.
#   Defaults to 'services'.
#
# [*public_url*]
#   (optional) The endpoint's public url. (Defaults to 'http://127.0.0.1:8000/v1')
#   This url should *not* contain any trailing '/'.
#
# [*admin_url*]
#   (optional) The endpoint's admin url. (Defaults to 'http://127.0.0.1:8000/v1')
#   This url should *not* contain any trailing '/'.
#
# [*internal_url*]
#   (optional) The endpoint's internal url. (Defaults to 'http://127.0.0.1:8000/v1')
#   This url should *not* contain any trailing '/'.
#
# [*version*]
#   (optional) DEPRECATED: Use public_url, internal_url and admin_url instead.
#   API version endpoint. (Defaults to 'v1')
#   Setting this parameter overrides public_url, internal_url and admin_url parameters.
#
# [*port*]
#   (optional) DEPRECATED: Use public_url, internal_url and admin_url instead.
#   Default port for endpoints. (Defaults to 8000)
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
#  class { 'heat::keystone::auth_cfn':
#    public_url   => 'https://10.0.0.10:8000/v1',
#    internal_url => 'https://10.0.0.11:8000/v1',
#    admin_url    => 'https://10.0.0.11:8000/v1',
#  }
#
class heat::keystone::auth_cfn (
  $password             = false,
  $email                = 'heat-cfn@localhost',
  $auth_name            = 'heat-cfn',
  $service_name         = undef,
  $service_type         = 'cloudformation',
  $region               = 'RegionOne',
  $tenant               = 'services',
  $configure_endpoint   = true,
  $configure_service    = true,
  $configure_user       = true,
  $configure_user_role  = true,
  $public_url           = 'http://127.0.0.1:8000/v1',
  $admin_url            = 'http://127.0.0.1:8000/v1',
  $internal_url         = 'http://127.0.0.1:8000/v1',
  # DEPRECATED PARAMETERS
  $version              = undef,
  $port                 = undef,
  $public_protocol      = undef,
  $public_address       = undef,
  $internal_protocol    = undef,
  $internal_address     = undef,
  $admin_protocol       = undef,
  $admin_address        = undef,
) {

  validate_string($password)

  if $version {
    warning('The version parameter is deprecated, use public_url, internal_url and admin_url instead.')
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

  if ($public_protocol or $public_address or $port or $version) {
    $public_url_real = sprintf('%s://%s:%s/%s',
      pick($public_protocol, 'http'),
      pick($public_address, '127.0.0.1'),
      pick($port, '8000'),
      pick($version, 'v1'))
  } else {
    $public_url_real = $public_url
  }

  if ($admin_protocol or $admin_address or $port or $version) {
    $admin_url_real = sprintf('%s://%s:%s/%s',
      pick($admin_protocol, 'http'),
      pick($admin_address, '127.0.0.1'),
      pick($port, '8000'),
      pick($version, 'v1'))
  } else {
    $admin_url_real = $admin_url
  }

  if ($internal_protocol or $internal_address or $port or $version) {
    $internal_url_real = sprintf('%s://%s:%s/%s',
      pick($internal_protocol, 'http'),
      pick($internal_address, '127.0.0.1'),
      pick($port, '8000'),
      pick($version, 'v1'))
  } else {
    $internal_url_real = $internal_url
  }

  $real_service_name = pick($service_name, $auth_name)

  keystone::resource::service_identity { $auth_name:
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    configure_service   => $configure_service,
    service_type        => $service_type,
    service_description => 'Openstack Cloudformation Service',
    service_name        => $real_service_name,
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
  }

  if $configure_user_role {
    Keystone_user_role["${auth_name}@${tenant}"] ~>
      Service <| name == 'heat-api-cfn' |>
  }

}
