#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# ironic::keystone::auth
#
# Configures Ironic user, service and endpoint in Keystone.
#
# === Parameters
#
# [*password*]
#   (required) Password for Ironic user.
#
# [*auth_name*]
#   Username for Ironic service. Defaults to 'ironic'.
#
# [*email*]
#   Email for Ironic user. Defaults to 'ironic@localhost'.
#
# [*tenant*]
#   Tenant for Ironic user. Defaults to 'services'.
#
# [*configure_endpoint*]
#   Should Ironic endpoint be configured? Defaults to 'true'.
#
# [*configure_user*]
#   (Optional) Should the service user be configured?
#   Defaults to 'true'.
#
# [*configure_user_role*]
#   (Optional) Should the admin role be configured for the service user?
#   Defaults to 'true'.
#
# [*service_name*]
#   (Optional) Name of the service.
#   Defaults to the value of auth_name, but must differ from the value.
#
# [*service_type*]
#   Type of service. Defaults to 'baremetal'.
#
# [*service_description*]
#   (Optional) Description for keystone service.
#   Defaults to 'Ironic Bare Metal Provisioning Service'.
#
# [*region*]
#   Region for endpoint. Defaults to 'RegionOne'.
#
# [*public_url*]
#   (optional) The endpoint's public url. (Defaults to 'http://127.0.0.1:6385')
#   This url should *not* contain any trailing '/'.
#
# [*admin_url*]
#   (optional) The endpoint's admin url. (Defaults to 'http://127.0.0.1:6385')
#   This url should *not* contain any trailing '/'.
#
# [*internal_url*]
#   (optional) The endpoint's internal url. (Defaults to 'http://127.0.0.1:6385')
#   This url should *not* contain any trailing '/'.
#
# [*port*]
#   (optional) DEPRECATED: Use public_url, internal_url and admin_url instead.
#   Default port for endpoints. (Defaults to 6385)
#   Setting this parameter overrides public_url, internal_url and admin_url parameters.
#
# [*public_protocol*]
#   (optional) DEPRECATED: Use public_url instead.
#   Protocol for public endpoint. (Defaults to 'http')
#   Setting this parameter overrides public_url parameter.
#
# [*public_port*]
#   (optional) DEPRECATED: Use public_url instead.
#   Default port for endpoints. (Defaults to $port)
#   Setting this parameter overrides public_url parameter.
#
# [*public_address*]
#   (optional) DEPRECATED: Use public_url instead.
#   Public address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides public_url parameter.
#
# [*internal_address*]
#   (optional) DEPRECATED: Use internal_url instead.
#   Internal address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides internal_url parameter.
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
#  class { 'ironic::keystone::auth':
#    public_url   => 'https://10.0.0.10:6385',
#    internal_url => 'https://10.0.0.11:6385',
#    admin_url    => 'https://10.0.0.11:6385',
#  }
#
class ironic::keystone::auth (
  $password,
  $auth_name           = 'ironic',
  $email               = 'ironic@localhost',
  $tenant              = 'services',
  $configure_endpoint  = true,
  $configure_user      = true,
  $configure_user_role = true,
  $service_name        = undef,
  $service_type        = 'baremetal',
  $service_description = 'Ironic Bare Metal Provisioning Service',
  $public_protocol     = 'http',
  $region              = 'RegionOne',
  $public_url          = 'http://127.0.0.1:6385',
  $admin_url           = 'http://127.0.0.1:6385',
  $internal_url        = 'http://127.0.0.1:6385',
  # DEPRECATED PARAMETERS
  $port                = undef,
  $public_protocol     = undef,
  $public_address      = undef,
  $public_port         = undef,
  $internal_address    = undef,
  $admin_address       = undef,
) {

  if $port {
    warning('The port parameter is deprecated, use public_url, internal_url and admin_url instead.')
  }

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

  if $admin_address {
    warning('The admin_address parameter is deprecated, use admin_url instead.')
  }

  if ($public_protocol or $public_address or $port or $public_port) {
    $public_url_real = sprintf('%s://%s:%s',
      pick($public_protocol, 'http'),
      pick($public_address, '127.0.0.1'),
      pick($public_port, $port, '6385'))
  } else {
    $public_url_real = $public_url
  }

  if ($admin_address or $port) {
    $admin_url_real = sprintf('http://%s:%s',
      pick($admin_address, '127.0.0.1'),
      pick($port, '6385'))
  } else {
    $admin_url_real = $admin_url
  }

  if ($internal_address or $port) {
    $internal_url_real = sprintf('http://%s:%s',
      pick($internal_address, '127.0.0.1'),
      pick($port, '6385'))
  } else {
    $internal_url_real = $internal_url
  }

  $real_service_name = pick($service_name, $auth_name)

  if $configure_user_role {
    Keystone_user_role["${auth_name}@${tenant}"] ~> Service <| name == 'ironic-server' |>
  }

  Keystone_endpoint["${region}/${real_service_name}"]  ~> Service <| name == 'ironic-server' |>

  keystone::resource::service_identity { $auth_name:
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_name        => $real_service_name,
    service_type        => $service_type,
    service_description => $service_description,
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $public_url_real,
    internal_url        => $internal_url_real,
    admin_url           => $admin_url_real,
  }

}
