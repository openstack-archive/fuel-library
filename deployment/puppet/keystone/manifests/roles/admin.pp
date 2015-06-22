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
#   Defaulst to 'true'.
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
) {

  keystone_tenant { $service_tenant:
    ensure      => present,
    enabled     => true,
    description => $service_tenant_desc,
  }
  keystone_tenant { $admin_tenant:
    ensure      => present,
    enabled     => true,
    description => $admin_tenant_desc,
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
