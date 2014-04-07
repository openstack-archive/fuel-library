# == Class: keystone::endpoint
#
# Creates the auth endpoints for keystone
#
# === Parameters
#
# [*public_url*]
#   (optional) Public url for keystone endpoint. (Defaults to 'http://127.0.0.1:5000')
#
# [*internal_url*]
#   (optional) Internal url for keystone endpoint. (Defaults to $public_url)
#
# [*admin_url*]
#   (optional) Admin url for keystone endpoint. (Defaults to 'http://127.0.0.1:35357')
#
# [*region*]
#   (optional) Region for endpoint. (Defaults to 'RegionOne')
#
# [*version*]
#   (optional) API version for endpoint. Appended to all endpoint urls. (Defaults to 'v2.0')
#
# [*public_url*]
#   (optional) The endpoint's public url. (Defaults to 'http://127.0.0.1:5000')
#   This url should *not* contain any version or trailing '/'.
#
# [*admin_url*]
#   (optional) The endpoint's admin url. (Defaults to 'http://127.0.0.1:5000')
#   This url should *not* contain any version or trailing '/'.
#
# [*internal_url*]
#   (optional) The endpoint's internal url. (Defaults to 'http://127.0.0.1:35357')
#   This url should *not* contain any version or trailing '/'.
#
# [*public_protocol*]
#   (optional) DEPRECATED: Use public_url instead.
#   Protocol for public access to keystone endpoint. (Defaults to 'http')
#   Setting this parameter overrides public_url parameter.
#
# [*public_address*]
#   (optional) DEPRECATED: Use public_url instead.
#   Public address for keystone endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides public_url parameter.
#
# [*public_port*]
#   (optional) DEPRECATED: Use public_url instead.
#   Port for non-admin access to keystone endpoint. (Defaults to 5000)
#   Setting this parameter overrides public_url parameter.
#
# [*internal_address*]
#   (optional) DEPRECATED: Use internal_url instead.
#   Internal address for keystone endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides internal_url parameter.
#
# [*internal_port*]
#   (optional) DEPRECATED: Use internal_url instead.
#   Port for internal access to keystone endpoint. (Defaults to $public_port)
#   Setting this parameter overrides internal_url parameter.
#
# [*admin_address*]
#   (optional) DEPRECATED: Use admin_url instead.
#   Admin address for keystone endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides admin_url parameter.
#
# [*admin_port*]
#   (optional) DEPRECATED: Use admin_url instead.
#   Port for admin access to keystone endpoint. (Defaults to 35357)
#   Setting this parameter overrides admin_url parameter.
#
# === Deprecation notes
#
# If any value is provided for public_protocol, public_address or public_port parameters,
# public_url will be completely ignored. The same applies for internal and admin parameters.
#
# === Examples
#
#  class { 'keystone::endpoint':
#    public_url   => 'https://154.10.10.23:5000',
#    internal_url => 'https://11.0.1.7:5000',
#    admin_url    => 'https://10.0.1.7:35357',
#  }
#
class keystone::endpoint (
  $public_url        = 'http://127.0.0.1:5000',
  $internal_url      = undef,
  $admin_url         = 'http://127.0.0.1:35357',
  $version           = 'v2.0',
  $region            = 'RegionOne',
  # DEPRECATED PARAMETERS
  $public_protocol   = undef,
  $public_address    = undef,
  $public_port       = undef,
  $internal_address  = undef,
  $internal_port     = undef,
  $admin_address     = undef,
  $admin_port        = undef,
) {

  if $public_port {
    warning('The public_port parameter is deprecated, use public_url instead.')
  }

  if $public_protocol {
    warning('The public_protocol parameter is deprecated, use public_url instead.')
  }

  if $public_address {
    warning('The public_address parameter is deprecated, use public_url instead.')
  }

  if $internal_address {
    warning('The internal_address parameter is deprecated, use internal_url instead.')
  }

  if $internal_port {
    warning('The internal_port parameter is deprecated, use internal_url instead.')
  }

  if $admin_address {
    warning('The admin_address parameter is deprecated, use admin_url instead.')
  }

  if $admin_port {
    warning('The admin_port parameter is deprecated, use admin_url instead.')
  }

  $public_url_real = inline_template('<%=
    if (!@public_protocol.nil?) || (!@public_address.nil?) || (!@public_port.nil?)
      @public_protocol ||= "http"
      @public_address ||= "127.0.0.1"
      @public_port ||= "5000"
      "#{@public_protocol}://#{@public_address}:#{@public_port}/#{@version}"
    else
      "#{@public_url}/#{@version}"
    end %>')

  $internal_url_real = inline_template('<%=
    if (!@internal_address.nil?) || (!@internal_port.nil?) || (!@public_port.nil?)
      @internal_address ||= @public_address ||= "127.0.0.1"
      @internal_port ||= @public_port ||= "5000"
      "http://#{@internal_address}:#{@internal_port}/#{@version}"
    elsif (!@internal_url.nil?)
      "#{@internal_url}/#{@version}"
    else
      "#{@public_url}/#{@version}"
    end %>')

  $admin_url_real = inline_template('<%=
    if (!@admin_address.nil?) || (!@admin_port.nil?)
      @admin_address ||= "127.0.0.1"
      @admin_port ||= "35357"
      "http://#{@admin_address}:#{@admin_port}/#{@version}"
    else
      "#{@admin_url}/#{@version}"
    end %>')

  keystone_service { 'keystone':
    ensure      => present,
    type        => 'identity',
    description => 'OpenStack Identity Service',
  }

  keystone_endpoint { "${region}/keystone":
    ensure       => present,
    public_url   => $public_url_real,
    admin_url    => $admin_url_real,
    internal_url => $internal_url_real,
    region       => $region,
  }
}
