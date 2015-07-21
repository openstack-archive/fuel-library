# == Class: keystone::roles::admin
#
# This class implements some reasonable admin defaults for keystone.
#
# It creates the following keystone objects:
#   * service tenant (tenant used by all service users)
#   * "admin" tenant (defaults to "openstack")
#   * admin user (that defaults to the "admin" tenant)
#   * admin role
#   * adds admin role to admin user on the "admin" tenant
#
# === Parameters:
#
# [*email*]
#   The email address for the admin. Required.
#
# [*password*]
#   The admin password. Required.
#
# [*admin_roles*]
#   The list of the roles with admin privileges. Optional.
#   Defaults to ['admin'].
#
# [*admin_tenant*]
#   The name of the tenant to be used for admin privileges. Optional.
#   Defaults to openstack.
#
# [*service_tenant*]
#   The name of service keystone tenant. Optional.
#   Defaults to 'services'.
#
# [*admin*]
#   Admin user. Optional.
#   Defaults to admin.
#
# [*ignore_default_tenant*]
#   Ignore setting the default tenant value when the user is created. Optional.
#   Defaults to false.
#
# [*admin_tenant_desc*]
#   Optional. Description for admin tenant,
#   Defaults to 'admin tenant'
#
# [*service_tenant_desc*]
#   Optional. Description for admin tenant,
#   Defaults to 'Tenant for the openstack services'
#
# [*configure_user*]
#   Optional. Should the admin user be created?
#   Defaults to 'true'.
#
# [*configure_user_role*]
#   Optional. Should the admin role be configured for the admin user?
#   Defaults to 'true'.
#
# [*admin_user_domain*]
#   Optional.  Domain of the admin user
#   Defaults to undef (undef will resolve to class keystone $default_domain)
#
# [*admin_project_domain*]
#   Optional.  Domain of the admin tenant
#   Defaults to undef (undef will resolve to class keystone $default_domain)
#
# [*service_project_domain*]
#   Optional.  Domain for $service_tenant
#   Defaults to undef (undef will resolve to class keystone $default_domain)
#
# == Dependencies
# == Examples
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone::roles::admin(
  $email,
  $password,
  $admin                  = 'admin',
  $admin_tenant           = 'openstack',
  $admin_roles            = ['admin'],
  $service_tenant         = 'services',
  $ignore_default_tenant  = false,
  $admin_tenant_desc      = 'admin tenant',
  $service_tenant_desc    = 'Tenant for the openstack services',
  $configure_user         = true,
  $configure_user_role    = true,
  $admin_user_domain      = undef,
  $admin_project_domain   = undef,
  $service_project_domain = undef,
) {

  if $service_project_domain {
    if $service_project_domain != $admin_user_domain {
      if $service_project_domain != $admin_project_domain {
        keystone_domain { $service_project_domain:
          ensure  => present,
          enabled => true,
        }
      }
    }
  }

  if $admin_project_domain {
    if $admin_project_domain != $admin_user_domain {
      if $service_project_domain != $admin_project_domain {
        keystone_domain { $admin_project_domain:
          ensure  => present,
          enabled => true,
        }
      }
    }
  }

  if $admin_user_domain {
    if $admin_project_domain != $admin_user_domain {
      if $service_project_domain != $admin_user_domain {
        keystone_domain { $admin_user_domain:
          ensure  => present,
          enabled => true,
        }
      }
    }
  }

  keystone_tenant { $service_tenant:
    ensure      => present,
    enabled     => true,
    description => $service_tenant_desc,
    domain      => $service_project_domain,
  }
  keystone_tenant { $admin_tenant:
    ensure      => present,
    enabled     => true,
    description => $admin_tenant_desc,
    domain      => $admin_project_domain,
  }
  keystone_role { 'admin':
    ensure => present,
  }

  if $configure_user {
    keystone_user { $admin:
      ensure                => present,
      enabled               => true,
      tenant                => $admin_tenant,
      email                 => $email,
      password              => $password,
      domain                => $admin_user_domain,
      ignore_default_tenant => $ignore_default_tenant,
    }
  }

  if $configure_user_role {
    keystone_user_role { "${admin}@${admin_tenant}":
      ensure => present,
      roles  => $admin_roles,
    }
  }

}
