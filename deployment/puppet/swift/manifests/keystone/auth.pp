# == Class: swift::keystone::auth
#
# This class creates keystone users, services, endpoints, and roles
# for swift services.
#
# The user is given the admin role in the services tenant.
#
# === Parameters:
#
# [*auth_name*]
#  String. The name of the user.
#  Optional. Defaults to 'swift'.
#
# [*password*]
#  String. The user's password.
#  Optional. Defaults to 'swift_password'.
#
# [*tenant*]
#   (Optional) The tenant to use for the swift service user
#   Defaults to 'services'
#
# [*email*]
#   (Optional) The email address for the swift service user
#   Defaults to 'swift@localhost'
#
# [*region*]
#   (Optional) The region in which to place the endpoints
#   Defaults to 'RegionOne'
#
# [*operator_roles*]
#  (Optional) Array of strings. List of roles Swift considers as admin.
#  Defaults to '['admin', 'SwiftOperator']'
#
# [*configure_endpoint*]
#   (optional) Whether to create the endpoint.
#   Defaults to true
#
# [*configure_s3_endpoint*]
#   (optional) Whether to create the S3 endpoint.
#   Defaults to true
#
# [*service_name*]
#   (optional) Name of the service.
#   Defaults to the value of auth_name, but must differ from the value
#   of service_name_s3.
#
# [*service_name_s3*]
#   (optional) Name of the s3 service.
#   Defaults to the value of auth_name_s3, but must differ from the value
#   of service_name.
#
# [*public_url*]
#   (optional) The endpoint's public url. (Defaults to 'http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s')
#   This url should *not* contain any trailing '/'.
#
# [*admin_url*]
#   (optional) The endpoint's admin url. (Defaults to 'http://127.0.0.1:8080')
#   This url should *not* contain any trailing '/'.
#
# [*internal_url*]
#   (optional) The endpoint's internal url. (Defaults to 'http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s')
#   This url should *not* contain any trailing '/'.
#
# [*public_url_s3*]
#   (optional) The endpoint's public url. (Defaults to 'http://127.0.0.1:8080')
#   This url should *not* contain any trailing '/'.
#
# [*admin_url_s3*]
#   (optional) The endpoint's admin url. (Defaults to 'http://127.0.0.1:8080')
#   This url should *not* contain any trailing '/'.
#
# [*internal_url_s3*]
#   (optional) The endpoint's internal url. (Defaults to 'http://127.0.0.1:8080')
#   This url should *not* contain any trailing '/'.
#
# [*endpoint_prefix*]
#   (optional) DEPRECATED: Use public_url, internal_url and admin_url instead.
#   The prefix endpoint, used for endpoint URL. (Defaults to 'AUTH')
#   Setting this parameter overrides public_url, internal_url and admin_url parameters.
#
# [*port*]
#   (optional) DEPRECATED: Use public_url(_s3), internal_url(_s3) and admin_url(_s3) instead.
#   Default port for endpoints. (Defaults to 8080)
#   Setting this parameter overrides public_url(_s3), internal_url(_s3) and admin_url(_s3) parameters.
#
# [*public_port*]
#   (optional) DEPRECATED: Use public_url(_s3) instead.
#   Default port for endpoints. (Defaults to $port)
#   Setting this parameter overrides public_url(_s3) parameter.
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
#  class { 'swift::keystone::auth':
#    public_url      => 'https://10.0.0.10:8080/v1/AUTH_%(tenant_id)s',
#    internal_url    => 'https://10.0.0.11:8080/v1/AUTH_%(tenant_id)s',
#    admin_url       => 'https://10.0.0.11:8080',
#    public_url_s3   => 'https://10.0.0.10:8080',
#    internal_url_s3 => 'https://10.0.0.11:8080',
#    admin_url_s3    => 'https://10.0.0.11:8080',
#  }
#
class swift::keystone::auth(
  $auth_name              = 'swift',
  $password               = 'swift_password',
  $tenant                 = 'services',
  $email                  = 'swift@localhost',
  $region                 = 'RegionOne',
  $operator_roles         = ['admin', 'SwiftOperator'],
  $service_name           = undef,
  $service_name_s3        = undef,
  $configure_endpoint     = true,
  $configure_s3_endpoint  = true,
  $public_url             = 'http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s',
  $admin_url              = 'http://127.0.0.1:8080',
  $internal_url           = 'http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s',
  $public_url_s3          = 'http://127.0.0.1:8080',
  $admin_url_s3           = 'http://127.0.0.1:8080',
  $internal_url_s3        = 'http://127.0.0.1:8080',
  # DEPRECATED PARAMETERS
  $endpoint_prefix        = undef,
  $port                   = undef,
  $public_port            = undef,
  $public_protocol        = undef,
  $public_address         = undef,
  $internal_protocol      = undef,
  $internal_address       = undef,
  $admin_protocol         = undef,
  $admin_address          = undef,
) {

  if $endpoint_prefix {
    warning('The endpoint_prefix parameter is deprecated, use public_url, internal_url and admin_url instead.')
  }

  if $port {
    warning('The port parameter is deprecated, use public_url, internal_url, admin_url, public_url_s3, internal_url_s3 and admin_url_s3 instead.')
  }

  if $public_port {
    warning('The public_port parameter is deprecated, use public_url and public_url_s3 instead.')
  }

  if $public_protocol {
    warning('The public_protocol parameter is deprecated, use public_url and public_url_s3 instead.')
  }

  if $internal_protocol {
    warning('The internal_protocol parameter is deprecated, use internal_url and internal_url_s3 instead.')
  }

  if $admin_protocol {
    warning('The admin_protocol parameter is deprecated, use admin_url and admin_url_s3 instead.')
  }

  if $public_address {
    warning('The public_address parameter is deprecated, use public_url and public_url_s3 instead.')
  }

  if $internal_address {
    warning('The internal_address parameter is deprecated, use internal_url and internal_url_s3 instead.')
  }

  if $admin_address {
    warning('The admin_address parameter is deprecated, use admin_url and admin_url_s3 instead.')
  }

  if ($public_protocol or $public_address or $port or $public_port or $endpoint_prefix) {
    $public_url_real = sprintf('%s://%s:%s/v1/%s_%%(tenant_id)s',
      pick($public_protocol, 'http'),
      pick($public_address, '127.0.0.1'),
      pick($public_port, $port, '8080'),
      pick($endpoint_prefix, 'AUTH'))
  } else {
    $public_url_real = $public_url
  }

  if ($admin_protocol or $admin_address or $public_address or $port) {
    $admin_url_real = sprintf('%s://%s:%s',
      pick($admin_protocol, 'http'),
      pick($admin_address, $public_address, '127.0.0.1'),
      pick($port, '8080'))
  } else {
    $admin_url_real = $admin_url
  }

  if ($internal_protocol or $internal_address or $public_address or $port or $endpoint_prefix) {
    $internal_url_real = sprintf('%s://%s:%s/v1/%s_%%(tenant_id)s',
      pick($internal_protocol, 'http'),
      pick($internal_address, $public_address, '127.0.0.1'),
      pick($port, '8080'),
      pick($endpoint_prefix, 'AUTH'))
  } else {
    $internal_url_real = $internal_url
  }

  if ($public_protocol or $public_address or $port or $public_port) {
    $public_url_s3_real = sprintf('%s://%s:%s',
      pick($public_protocol, 'http'),
      pick($public_address, '127.0.0.1'),
      pick($public_port, $port, '8080'))
  } else {
    $public_url_s3_real = $public_url_s3
  }

  if ($admin_protocol or $admin_address or $public_address or $port) {
    $admin_url_s3_real = sprintf('%s://%s:%s',
      pick($admin_protocol, 'http'),
      pick($admin_address, $public_address, '127.0.0.1'),
      pick($port, '8080'))
  } else {
    $admin_url_s3_real = $admin_url_s3
  }

  if ($internal_protocol or $internal_address or $public_address or $port) {
    $internal_url_s3_real = sprintf('%s://%s:%s',
      pick($internal_protocol, 'http'),
      pick($internal_address, $public_address, '127.0.0.1'),
      pick($port, '8080'))
  } else {
    $internal_url_s3_real = $internal_url_s3
  }

  $real_service_name    = pick($service_name, $auth_name)
  $real_service_name_s3 = pick($service_name_s3, "${auth_name}_s3")

  if $real_service_name == $real_service_name_s3 {
      fail('cinder::keystone::auth parameters service_name and service_name_s3 must be different.')
  }

  keystone::resource::service_identity { 'swift':
    configure_endpoint  => $configure_endpoint,
    service_name        => $real_service_name,
    service_type        => 'object-store',
    service_description => 'Openstack Object-Store Service',
    region              => $region,
    auth_name           => $auth_name,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
  }

  keystone::resource::service_identity { 'swift_s3':
    configure_user      => false,
    configure_user_role => false,
    configure_endpoint  => $configure_s3_endpoint,
    configure_service   => $configure_s3_endpoint,
    service_name        => $real_service_name_s3,
    service_type        => 's3',
    service_description => 'Openstack S3 Service',
    region              => $region,
    public_url          => $public_url_s3_real,
    admin_url           => $admin_url_s3_real,
    internal_url        => $internal_url_s3_real,
  }

  if $operator_roles {
    #Roles like "admin" may be defined elsewhere, so use ensure_resource
    ensure_resource('keystone_role', $operator_roles, { 'ensure' => 'present' })
  }

  # Backward compatibility
  Keystone_user[$auth_name] -> Keystone_user_role["${auth_name}@${tenant}"]

}
