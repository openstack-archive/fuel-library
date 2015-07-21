#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
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
# == Definition: keystone::resource::service_identity
#
# This resource configures Keystone resources for an OpenStack service.
#
# == Parameters:
#
# [*password*]
#   Password to create for the service user;
#   string; required
#
# [*auth_name*]
#   The name of the service user;
#   string; optional; default to the $title of the resource, i.e. 'nova'
#
# [*service_name*]
#   Name of the service;
#   string; required
#
# [*service_type*]
#   Type of the service;
#   string; required
#
# [*service_description*]
#   Description of the service;
#   string; optional: default to '$name service'
#
# [*public_url*]
#   Public endpoint URL;
#   string; required
#
# [*internal_url*]
#   Internal endpoint URL;
#   string; required
#
# [*admin_url*]
#   Admin endpoint URL;
#   string; required
#
# [*region*]
#   Endpoint region;
#   string; optional: default to 'RegionOne'
#
# [*tenant*]
#   Service tenant;
#   string; optional: default to 'services'
#
# [*ignore_default_tenant*]
#   Ignore setting the default tenant value when the user is created.
#   string; optional: default to false
#
# [*roles*]
#   List of roles;
#   string; optional: default to ['admin']
#
# [*email*]
#   Service email;
#   string; optional: default to '$auth_name@localhost'
#
# [*configure_endpoint*]
#   Whether to create the endpoint.
#   string; optional: default to True
#
# [*configure_user*]
#   Whether to create the user.
#   string; optional: default to True
#
# [*configure_user_role*]
#   Whether to create the user role.
#   string; optional: default to True
#
# [*configure_service*]
#   Whether to create the service.
#   string; optional: default to True
#
# [*user_domain*]
#   (Optional) Domain for $auth_name
#   Defaults to undef (use the keystone server default domain)
#
# [*project_domain*]
#   (Optional) Domain for $tenant (project)
#   Defaults to undef (use the keystone server default domain)
#
# [*default_domain*]
#   (Optional) Domain for $auth_name and $tenant (project)
#   If keystone_user_domain is not specified, use $keystone_default_domain
#   If keystone_project_domain is not specified, use $keystone_default_domain
#   Defaults to undef
#
define keystone::resource::service_identity(
  $admin_url             = false,
  $internal_url          = false,
  $password              = false,
  $public_url            = false,
  $service_type          = false,
  $auth_name             = $name,
  $configure_endpoint    = true,
  $configure_user        = true,
  $configure_user_role   = true,
  $configure_service     = true,
  $email                 = "${name}@localhost",
  $region                = 'RegionOne',
  $service_name          = undef,
  $service_description   = "${name} service",
  $tenant                = 'services',
  $ignore_default_tenant = false,
  $roles                 = ['admin'],
  $user_domain           = undef,
  $project_domain        = undef,
  $default_domain        = undef,
) {
  if $service_name == undef {
    $service_name_real = $auth_name
  } else {
    $service_name_real = $service_name
  }

  if $user_domain == undef {
    $user_domain_real = $default_domain
  } else {
    $user_domain_real = $user_domain
  }

  if $configure_user {
    if $user_domain_real {
      # We have to use ensure_resource here and hope for the best, because we have
      # no way to know if the $user_domain is the same domain passed as the
      # $default_domain parameter to class keystone.
      ensure_resource('keystone_domain', $user_domain_real, {
        'ensure'  => 'present',
        'enabled' => true,
      })
    }
    ensure_resource('keystone_user', $auth_name, {
      'ensure'                => 'present',
      'enabled'               => true,
      'password'              => $password,
      'email'                 => $email,
      'tenant'                => $tenant,
      'ignore_default_tenant' => $ignore_default_tenant,
      'domain'                => $user_domain_real,
    })
  }

  if $configure_user_role {
    ensure_resource('keystone_user_role', "${auth_name}@${tenant}", {
      'ensure' => 'present',
      'roles'  => $roles,
    })
  }

  if $configure_service {
    ensure_resource('keystone_service', $service_name_real, {
      'ensure'      => 'present',
      'type'        => $service_type,
      'description' => $service_description,
    })
  }

  if $configure_endpoint {
    ensure_resource('keystone_endpoint', "${region}/${service_name_real}", {
      'ensure'       => 'present',
      'public_url'   => $public_url,
      'admin_url'    => $admin_url,
      'internal_url' => $internal_url,
    })
  }
}
